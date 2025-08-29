import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:nip01/nip01.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

const relay = 'wss://relay.damus.io';
const eventId =
    '4710d4f12e7f50106f2f4d2f1def4c384373921579b25ff49e3516baa7e010ab';

enum FetchState {
  fetching(message: 'fetching an event...'),
  composing(message: 'creating a playlist as a Data URI...');

  const FetchState({required this.message});

  final String message;
}

class VideoData extends ChangeNotifier {
  VideoData() {
    unawaited(fetch());
  }

  final _log = Logger('VideoData');
  FetchState fetchState = FetchState.fetching;
  String? data;

  Future<void> fetch() async {
    // await Future.delayed(Duration(seconds: 2));
    // data = expectedData;
    // notifyListeners();
    // return;

    final relayDataSource = WebSocketRelayDataSource();
    final relayRepository = RelayRepositoryImpl(
      relayDataSource: relayDataSource,
    );
    final eventRepository = EventRepositoryImpl(
      relayDataSource: relayDataSource,
    );
    final subscriptionRepository = SubscriptionRepositoryImpl(
      relayDataSource: relayDataSource,
    );

    final AddRelaysUseCase addRelaysUseCase = AddRelaysUseCase(
      relayRepository: relayRepository,
    );
    final SubscribeUseCase subscribeUseCase = SubscribeUseCase(
      subscriptionRepository: subscriptionRepository,
      eventRepository: eventRepository,
      relayRepository: relayRepository,
    );
    final UnsubscribeUseCase unsubscribeUseCase = UnsubscribeUseCase(
      subscriptionRepository: subscriptionRepository,
    );
    await addRelaysUseCase.execute([Uri.parse(relay)]);

    final textNoteFilters = [
      Filters(ids: [eventId]),
    ];
    final textNoteSubscription = await subscribeUseCase.execute(
      filters: textNoteFilters,
    );

    final comp = Completer<Event>();
    final textNoteListener = textNoteSubscription.eventStream.listen((event) {
      if (comp.isCompleted) {
        return;
      }
      comp.complete(event.event);
    });
    final event = await comp.future;
    _log.info('event: $event');
    fetchState = FetchState.composing;
    notifyListeners();

    List<String> urls = [];
    String duration = '';
    List<({String hash, String duration})> hashes = [];
    for (var tag in event.tags) {
      if (tag.length < 2) {
        continue;
      }
      final key = tag[0];
      switch (key) {
        case 'url':
          final p = path.normalize(tag[1]);
          urls.add(p);
          break;
        case 'duration':
          duration = tag[1];
          break;
        case 'x':
          if (tag.length > 2) {
            hashes.add((hash: tag[1], duration: tag[2]));
          }
          break;
      }
    }
    if (urls.isEmpty || duration.isEmpty || hashes.isEmpty) {
      throw Exception('broken event: $event');
    }

    // final selectedServer = urls.first;
    final selectedServer = 'https://blossom.sector01.com';

    StringBuffer buf = StringBuffer();

    buf.write(
      '#EXTM3U\n#EXT-X-VERSION:3\n#EXT-X-TARGETDURATION:$duration\n#EXT-X-MEDIA-SEQUENCE:0\n#EXT-X-PLAYLIST-TYPE:VOD\n',
    );
    for (var hash in hashes) {
      buf.write('#EXTINF:${hash.duration},\n$selectedServer/${hash.hash}\n');
    }
    buf.write('#EXT-X-ENDLIST');
    final playlist = buf.toString();

    final bytes = utf8.encode(playlist);
    final base64String = base64.encode(bytes);
    buf.clear();
    buf.write('data:application/vnd.apple.mpegurl;base64,');
    buf.write(base64String);
    final actualData = buf.toString();

    data = actualData;
    _log.info('data URI: $data');
    notifyListeners();

    await unsubscribeUseCase.execute(
      textNoteSubscription.subscription.id,
      relayUrls: textNoteSubscription.subscription.relayUrls,
    );
    await textNoteListener.cancel();
  }
}
