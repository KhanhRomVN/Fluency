import 'package:flutter/material.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  static final List<FaqItem> _faqs = [
    const FaqItem(
      question: 'Làm thế nào để nhập khóa học?',
      answer:
          'Vào trang Cài đặt, chọn "Nhập khóa học" và chọn file .zip chứa nội dung khóa học. Sau khi nhập thành công, khóa học sẽ xuất hiện trong danh sách khóa học.',
    ),
    const FaqItem(
      question: 'Làm thế nào để theo dõi tiến độ học tập?',
      answer:
          'Tiến độ học tập của bạn được tự động lưu sau mỗi bài quiz. Bạn có thể xem tiến độ chi tiết trong trang chi tiết khóa học.',
    ),
    const FaqItem(
      question: 'Tôi có thể xuất dữ liệu học tập không?',
      answer:
          'Có, bạn có thể xuất toàn bộ dữ liệu học tập của mình bằng cách vào Cài đặt > Xuất dữ liệu. Dữ liệu sẽ được lưu dưới dạng file JSON.',
    ),
    const FaqItem(
      question: 'Ứng dụng có hỗ trợ chế độ ngoại tuyến không?',
      answer:
          'Có, sau khi tải khóa học về, bạn có thể học mà không cần kết nối internet.',
    ),
    const FaqItem(
      question: 'Làm thế nào để đặt lại tiến độ học tập?',
      answer:
          'Hiện tại tính năng này chưa được hỗ trợ. Vui lòng liên hệ hỗ trợ nếu bạn cần xóa dữ liệu học tập.',
    ),
    const FaqItem(
      question: 'Tôi gặp lỗi khi phát audio, phải làm sao?',
      answer:
          'Hãy đảm bảo file audio có trong khóa học và thiết bị của bạn có thể phát định dạng file đó. Nếu vấn đề vẫn tiếp diễn, vui lòng liên hệ hỗ trợ.',
    ),
    const FaqItem(
      question: 'Ứng dụng có miễn phí không?',
      answer:
          'Có, ứng dụng hoàn toàn miễn phí. Bạn có thể sử dụng tất cả các tính năng mà không mất phí.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Câu hỏi thường gặp'),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _faqs.length + 1, // +1 for header
        itemBuilder: (context, index) {
          if (index == 0) {
            // Header
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.help_outline,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trợ giúp nhanh',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tìm câu trả lời cho các câu hỏi phổ biến',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final faq = _faqs[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _FaqExpansionTile(faq: faq, index: index),
          );
        },
      ),
    );
  }
}

class _FaqExpansionTile extends StatelessWidget {
  const _FaqExpansionTile({required this.faq, required this.index});
  final FaqItem faq;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.purple,
      Colors.blue,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.indigo,
      Colors.green,
    ];
    final color = colors[(index - 1) % colors.length];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.quiz,
              color: color,
              size: 22,
            ),
          ),
          title: Text(
            faq.question,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 20,
                    color: color,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      faq.answer,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.8),
                        height: 1.6,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FaqItem {
  const FaqItem({
    required this.question,
    required this.answer,
  });
  final String question;
  final String answer;
}
