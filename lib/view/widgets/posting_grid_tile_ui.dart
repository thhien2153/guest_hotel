import 'package:custom_rating_bar/custom_rating_bar.dart';
import 'package:flutter/material.dart';
import 'package:guest_hotel/model/posting_model.dart';

class PostingGridTileUi extends StatefulWidget {
  final PostingModel? posting;

  PostingGridTileUi({Key? key, this.posting}) : super(key: key);

  @override
  State<PostingGridTileUi> createState() => _PostingGridTileUiState();
}

class _PostingGridTileUiState extends State<PostingGridTileUi> {
  PostingModel? posting;

  @override
  void initState() {
    super.initState();
    posting = widget.posting;
    updateUI();
  }

  Future<void> updateUI() async {
    if (posting != null) {
      await posting!.getFirstImageFromStorage();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 3 / 2,
          child: (posting?.displayImages?.isEmpty ?? true)
              ? Container(
                  color: Colors.grey,
                  child: const Center(child: Text('No Image')),
                )
              : Image(
                  image: posting!.displayImages!.first,
                  fit: BoxFit.cover,
                ),
        ),
        Text(
          "${posting?.type ?? ''} ${posting?.city ?? ''}, ${posting?.country ?? ''}",
          maxLines: 2,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          posting?.name ?? '',
          maxLines: 1,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${posting?.price?.toString() ?? '0'}/night',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            RatingBar.readOnly(
              size: 28,
              maxRating: 5,
              initialRating: posting?.getCurrentRating() ?? 0,
              filledIcon: Icons.star,
              emptyIcon: Icons.star_border,
              filledColor: Colors.green,
            ),
          ],
        ),
      ],
    );
  }
}
