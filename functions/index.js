const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');
const { defineString } = require('firebase-functions/params');

// Initialize Firebase
admin.initializeApp();
const db = admin.firestore();

// Define Telegram Token parameter
const telegramToken = defineString('TELEGRAM_TOKEN');

/**
 * startEmergency
 * Sends alerts via Firebase Cloud Messaging (FCM) and Telegram.
 * No longer uses WhatsApp/Twilio.
 */
exports.startEmergency = functions.https.onCall(async (data, context) => {
    const { userId, summary, lat, lng, address, telegramChatIds } = data;
    const incidentId = `INCIDENT_${Date.now()}`;
    const liveLink = `https://${process.env.GCLOUD_PROJECT}.web.app/track/${incidentId}`;
    const mapsLink = `https://www.google.com/maps/search/?api=1&query=${lat},${lng}`;

    const incidentData = {
        userId,
        summary,
        address, 
        location: { lat, lng },
        status: 'active',
        tier: 1,
        triggeredAt: admin.firestore.FieldValue.serverTimestamp(),
        responded: false,
        liveLink: liveLink
    };

    await db.collection('incidents').doc(incidentId).set(incidentData);

    const alertMessage = `ECHO EMERGENCY: ${summary}\n\n📍 Exact Location: ${address || 'Coordinates Locked'}\n\n🌐 Live Tracking: ${liveLink}\n\n🗺️ Google Maps: ${mapsLink}`;
    const dispatchPromises = [];

    // 2. DISPATCH TELEGRAM ALERTS (DIRECT SHOT)
    if (telegramChatIds && Array.isArray(telegramChatIds)) {
        console.log(`ECHO: Dispatching to ${telegramChatIds.length} Telegram IDs`);
        telegramChatIds.forEach(chatId => {
            if (chatId) {
                const telegramUrl = `https://api.telegram.org/bot${telegramToken.value()}/sendMessage`;
                dispatchPromises.push(
                    axios.post(telegramUrl, {
                        chat_id: chatId,
                        text: `ECHO EMERGENCY ALERT\n\n${alertMessage}`,
                        parse_mode: 'Markdown'
                    }).then(() => console.log(`Telegram sent to ${chatId}`))
                      .catch(e => console.error(`Telegram Failed for ${chatId}:`, e.response?.data || e.message))
                );
            }
        });
    }

    // 3. DISPATCH FIREBASE CLOUD MESSAGING (FCM)
    try {
        const contactsSnapshot = await db.collection('users').doc(userId).collection('contacts').get();
        const fcmTokens = [];
        
        contactsSnapshot.docs.forEach(doc => {
            const contact = doc.data();
            
            // Collect FCM tokens
            if (contact.fcmToken) {
                fcmTokens.push(contact.fcmToken);
            }
        });

        // Send FCM Notifications
        if (fcmTokens.length > 0) {
            const fcmMessage = {
                notification: {
                    title: 'ECHO EMERGENCY ALERT',
                    body: `${summary} @ ${address || 'Location Locked'}`,
                },
                data: {
                    incidentId: incidentId,
                    type: 'emergency_sos',
                    click_action: 'FLUTTER_NOTIFICATION_CLICK'
                },
                tokens: fcmTokens,
            };
            dispatchPromises.push(
                admin.messaging().sendEachForMulticast(fcmMessage)
                    .then(response => console.log(`✓ FCM dispatched: ${response.successCount} successes`))
                    .catch(e => console.error('✗ FCM Dispatch Failed:', e))
            );
        }

    } catch (error) {
        console.error('✗ Failed to fetch contacts/tokens:', error);
    }

    await Promise.all(dispatchPromises);
    return { incidentId, liveLink };
});

/**
 * confirmResponse
 * Called when a contact clicks "I AM RESPONDING" on the web tracker.
 */
exports.confirmResponse = functions.https.onRequest(async (req, res) => {
    const { incidentId, contactName } = req.query;

    await db.collection('incidents').doc(incidentId).update({
        responded: true,
        responderName: contactName,
        respondedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    res.status(200).send("Response confirmed. The victim has been notified.");
});
