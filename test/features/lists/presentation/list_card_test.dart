import 'package:bookapp/features/lists/domain/entities/list_entities.dart';
import 'package:bookapp/features/lists/presentation/widgets/list_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('stats row fits a narrow phone even with large counts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 800);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListCard(
                list: ListEntity(
                  id: 'l1',
                  userId: 'u1',
                  userName: 'Reader',
                  title: 'A list with a fairly long title',
                  description: 'Description',
                  isPublic: true,
                  likeCount: 123456,
                  commentCount: 98765,
                  createdAt: DateTime(2026),
                  previewCoverImageUrls: const [],
                ),
                onTap: () {},
                onLikeTap: () async {},
                onSaveTap: () async {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('123456'), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_outline), findsOneWidget);
  });
}
