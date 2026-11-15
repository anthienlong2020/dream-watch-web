import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<web.IDBDatabase>? _db;

Future<web.IDBDatabase> _open() => _db ??= () {
      final c = Completer<web.IDBDatabase>();
      final req = web.window.indexedDB.open('dreamwatch', 1);
      req.onupgradeneeded = ((web.Event _) {
        (req.result as web.IDBDatabase).createObjectStore('kv');
      }).toJS;
      req.onsuccess = ((web.Event _) => c.complete(req.result as web.IDBDatabase)).toJS;
      req.onerror = ((web.Event _) => c.completeError(StateError('IndexedDB'))).toJS;
      return c.future;
    }();

Future<JSAny?> _wait(web.IDBRequest r) {
  final c = Completer<JSAny?>();
  r.onsuccess = ((web.Event _) => c.complete(r.result)).toJS;
  r.onerror = ((web.Event _) => c.completeError(StateError('IndexedDB'))).toJS;
  return c.future;
}

Future<web.IDBObjectStore> _store(String mode) async =>
    (await _open()).transaction('kv'.toJS, mode).objectStore('kv');

Future<void> blobPut(String key, String value) async {
  await _wait((await _store('readwrite')).put(value.toJS, key.toJS));
}

Future<String?> blobGet(String key) async {
  final r = await _wait((await _store('readonly')).get(key.toJS));
  return r == null ? null : (r as JSString).toDart;
}

Future<void> blobDelete(String key) async {
  await _wait((await _store('readwrite')).delete(key.toJS));
}
