function log(str) {
    $('#log').css('visibility', 'visible').prepend($('<p/>').text(str));
}

function drmRegister(onSuccess) {
    log('downloading register token');
    $.ajax('/register', {
        dataType:'text',
        success:function (registerToken) {
            var drmAgent = document.getElementById('drmAgent');
            drmAgent.onDRMMessageResult = function (msgID, resultMsg, resultCode) {
                log('DRM message result msgID=' + msgID + ' resultMsg=' + resultMsg + ' resultCode=' + resultCode);
                if (resultCode == 0) {
                    onSuccess();
                }
            };
            drmAgent.onDRMRightsError = function () {
                log('DRM rights error');
            };
            log('drmAgent.sendDRMMessage: ' + drmAgent.sendDRMMessage);
            drmAgent.sendDRMMessage("application/vnd.marlin.drm.actiontoken+xml", registerToken, 'urn:dvb:casystemid:19188');
            log("Sending to drmagent: " + registerToken);
        },
        error:function () {
            log('error loading register token');
        }
    });
}
