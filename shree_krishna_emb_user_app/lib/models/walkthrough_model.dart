import 'package:equatable/equatable.dart';

class WalkthroughPage extends Equatable {
  final int id;
  final String title;
  final String description;
  final String imagePath;
  final String backgroundColor;
  final String buttonText;

  const WalkthroughPage({
    required this.id,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.backgroundColor,
    required this.buttonText,
  });

  @override
  List<Object?> get props =>
      [id, title, description, imagePath, backgroundColor, buttonText];
}
