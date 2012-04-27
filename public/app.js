// Encode a string containing HTML so it can be rendered as text.
function encodeHtml(str) {
    return str.replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;');
}

// Log a message to the screen.
function log(message) {
    var log = document.getElementById('log');
    if (!log) return;

    log.style.visibility = 'visible';
    log.innerHTML += '<p>' + encodeHtml(message) + '</p>';
    log.scrollTop = log.scrollHeight;
}

// Simple XMLHttpRequest wrapper for making GET requests. Calls options.success
// callback with response text when the request is successful or options.error
// if it isn't
function ajaxGet(url, options) {
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function () {
        if (xhr.readyState == 4) {
            var callback = options[xhr.status == 200 ? 'success' : 'error'];
            callback && callback(xhr.responseText);
        }
    };
    xhr.open('get', url);
    xhr.send(null);
}

// Acquire a Marlin Broadband Registration transaction token and then redeems it
// using the NetTV drmAgent plugin. If everything goes right calls the onSuccess
// callback.
function drmRegister(onSuccess) {
    log('Acquiring register token...');
    ajaxGet('/register', {
        success:function (registerToken) {
            log('Register token acquired successfully: ' + registerToken);

            var drmAgent = document.getElementById('drmAgent');
            drmAgent.onDRMMessageResult = function (msgID, resultMsg, resultCode) {
                log('DRM message result msgID=' + msgID + ' resultMsg=' + resultMsg + ' resultCode=' + resultCode);
                if (resultCode == 0) {
                    onSuccess();
                }
            };
            drmAgent.onDRMRightsError = function () {
                log('DRM rights error.');
            };

            log('Sending register token as DRM message...');
            drmAgent.sendDRMMessage('application/vnd.marlin.drm.actiontoken+xml', registerToken, 'urn:dvb:casystemid:19188');
        },
        error:function () {
            log('Error loading register token');
        }
    });
}
