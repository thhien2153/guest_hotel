import 'package:flutter/material.dart';
import 'package:guest_hotel/model/posting_model.dart';

class PostingListTileUI extends StatefulWidget {
  PostingModel? posting;

  PostingListTileUI({
    super.key,
    this.posting,
  });

  @override
  State<PostingListTileUI> createState() => _PostingListTileUIState();
}

class _PostingListTileUIState extends State<PostingListTileUI> {
  PostingModel? posting;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    posting = widget.posting;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: ListTile(
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Text(
            posting!.name!,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        trailing: AspectRatio(
          aspectRatio: 3 / 2,
          child: Image(
            image: posting!.displayImages!.first,
            fit: BoxFit.fitWidth,
          ),
        ),
      ),
    );
  }
}
