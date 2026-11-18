import json
URLBASE = 'http://localhost:8091/'

def storage(edition='pro', **settings):
    s = {'presetName': 'Chuẩn', 'faceStyle': 'dream', 'seasonMode': 'off', 'tickOn': False,
         'chimeEnabled': True, 'showTime': True, 'showDate': True, 'installChipHidden': True}
    s.update(settings)
    return {'mvQuality': 'high', 'flutter.edition': json.dumps(edition), 'flutter.settings': json.dumps(json.dumps(s))}
