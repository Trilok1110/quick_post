/*
  Firebase Messaging Service Worker
  Handles background messages for web builds
*/

self.addEventListener('push', function(event) {
  if (!event.data) return;
  const data = event.data.json();
  const title = (data.notification && data.notification.title) || 'QuickPost';
  const body = (data.notification && data.notification.body) || '';
  const route = data.data && data.data.route ? data.data.route : '/';

  event.waitUntil(
    self.registration.showNotification(title, {
      body,
      icon: '/icons/Icon-192.png',
      data: { route },
    })
  );
});

self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  const route = event.notification && event.notification.data && event.notification.data.route ? event.notification.data.route : '/';
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(clientList) {
      for (var i = 0; i < clientList.length; i++) {
        var client = clientList[i];
        if ('focus' in client) {
          client.navigate(route);
          return client.focus();
        }
      }
      if (clients.openWindow) return clients.openWindow(route);
    })
  );
});
