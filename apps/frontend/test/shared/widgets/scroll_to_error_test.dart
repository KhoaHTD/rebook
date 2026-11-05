import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/shared/widgets/form_widgets.dart';

void main() {
  testWidgets('scrollToFirstFormError cuộn tới ô lỗi nằm ngoài màn hình', (
    tester,
  ) async {
    final form = GlobalKey<FormState>();
    late BuildContext screen;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              screen = context;
              return SingleChildScrollView(
                child: Form(
                  key: form,
                  child: Column(
                    children: [
                      const SizedBox(height: 3000),
                      TextFormField(
                        key: const Key('bad'),
                        validator: (v) => 'Lỗi',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('bad')).hitTestable(), findsNothing);
    form.currentState!.validate();
    scrollToFirstFormError(screen);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bad')).hitTestable(), findsOneWidget);
  });
}
