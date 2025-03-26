import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:guest_hotel/global.dart';
import 'package:guest_hotel/model/app_constants.dart';
import 'package:guest_hotel/model/posting_model.dart';
import 'package:guest_hotel/view/guestScreens/host_home_screen.dart';
import 'package:guest_hotel/view/widgets/amenities_ui.dart';
import 'package:image_picker/image_picker.dart';

class CreatePostingScreen extends StatefulWidget {
  PostingModel? posting;
  CreatePostingScreen({
    Key? key,
    this.posting,
  }) : super(key: key);

  @override
  State<CreatePostingScreen> createState() => _CreatePostingScreenState();
}

class _CreatePostingScreenState extends State<CreatePostingScreen> {
  final formKey = GlobalKey<FormState>();
  TextEditingController _nameTextEditingController = TextEditingController();
  TextEditingController _priceTextEditingController = TextEditingController();
  TextEditingController _descriptionTextEditingController =
      TextEditingController();
  TextEditingController _addressTextEditingController = TextEditingController();
  TextEditingController _cityTextEditingController = TextEditingController();
  TextEditingController _countryTextEditingController = TextEditingController();
  TextEditingController _amenitiesTextEditingController =
      TextEditingController();

  final List<String> residenceTypes = [
    'Detatched House',
    'Villa',
    'Apartment',
    'Condo',
    'Flat',
    'Town House',
    'Studio',
  ];

  late String residenceTypeSelected;

  Map<String, int> _beds = {'small': 0, 'medium': 0, 'large': 0};
  Map<String, int> _bathrooms = {'full': 0, 'half': 0};
  List<MemoryImage> _imagesList = [];

  Future<void> _selectImageFromGallery(int index) async {
    var imageFilePickedFromGallery =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (imageFilePickedFromGallery != null) {
      MemoryImage imageFileInBytesForm = MemoryImage(
          (File(imageFilePickedFromGallery.path)).readAsBytesSync());

      if (index < 0) {
        _imagesList.add(imageFileInBytesForm);
      } else {
        _imagesList[index] = imageFileInBytesForm;
      }

      setState(() {});
    }
  }

  void initializeValues() {
    if (widget.posting == null) {
      _nameTextEditingController.text = "";
      _priceTextEditingController.text = "";
      _descriptionTextEditingController.text = "";
      _addressTextEditingController.text = "";
      _cityTextEditingController.text = "";
      _countryTextEditingController.text = "";
      residenceTypeSelected = residenceTypes.first;

      _beds = {'small': 0, 'medium': 0, 'large': 0};

      _bathrooms = {'full': 0, 'half': 0};

      _imagesList = [];
    } else {
      _nameTextEditingController =
          TextEditingController(text: widget.posting!.name);
      _priceTextEditingController =
          TextEditingController(text: widget.posting!.price.toString());
      _descriptionTextEditingController =
          TextEditingController(text: widget.posting!.description);
      _addressTextEditingController =
          TextEditingController(text: widget.posting!.address);
      _cityTextEditingController =
          TextEditingController(text: widget.posting!.city);
      _countryTextEditingController =
          TextEditingController(text: widget.posting!.country);
      _amenitiesTextEditingController =
          TextEditingController(text: widget.posting!.getAmenititesString());
      _beds = widget.posting!.beds!;
      _bathrooms = widget.posting!.bathrooms!;
      _imagesList = widget.posting!.displayImages!;
      residenceTypeSelected = residenceTypes.contains(widget.posting!.type!)
          ? widget.posting!.type!
          : residenceTypes.first;
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    initializeValues();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Colors.green,
          ),
        ),
        title: const Text(
          "Create/Update a Listing",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) {
                return;
              }
              if (_imagesList.isEmpty) {
                return;
              }

              postingModel.name = _nameTextEditingController.text;
              postingModel.price =
                  double.tryParse(_priceTextEditingController.text) ?? 0.0;
              postingModel.description = _descriptionTextEditingController.text;
              postingModel.address = _addressTextEditingController.text;
              postingModel.city = _cityTextEditingController.text;
              postingModel.country = _countryTextEditingController.text;
              postingModel.amenities =
                  _amenitiesTextEditingController.text.split(",");
              postingModel.beds = _beds;
              postingModel.bathrooms = _bathrooms;
              postingModel.displayImages = _imagesList;

              postingModel.host =
                  AppConstants.currentUser.createUserFormContact();

              postingModel.setImagesName();

              if (widget.posting == null) {
                postingModel.rating = 3.5;
                postingModel.bookings = [];
                postingModel.reviews = [];

                await postingViewModel.addListingInfoToFirestore();
                await postingViewModel.addImagesToFirebaseStorage();
                Get.snackbar("New Listing",
                    "Your New Listing is uploaded successfully.");
              } else {
                postingModel.rating = widget.posting!.rating;
                postingModel.bookings = widget.posting!.bookings;
                postingModel.reviews = widget.posting!.reviews;
                postingModel.id = widget.posting!.id;

                for (int i = 0;
                    i < AppConstants.currentUser.myPostings!.length;
                    i++) {
                  if (AppConstants.currentUser.myPostings![i].id ==
                      postingModel.id) {
                    AppConstants.currentUser.myPostings![i] = postingModel;
                    break;
                  }
                }

                await postingViewModel.updatePostingInfoToFirestore();

                Get.snackbar(
                    "Update Listing", "Your Listing is updated successfully.");
              }

              postingModel = PostingModel();

              Get.to(HostHomeScreen());
            },
            icon: const Icon(Icons.upload_outlined),
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Listing name
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: TextFormField(
                          decoration:
                              const InputDecoration(labelText: "Listing name"),
                          style: const TextStyle(
                            fontSize: 25.0,
                          ),
                          controller: _nameTextEditingController,
                          validator: (textInput) {
                            if (textInput == null || textInput.isEmpty) {
                              return "Please Enter Your Name";
                            }
                            return null;
                          },
                        ),
                      ),

                      //Select property type
                      Padding(
                        padding: const EdgeInsets.only(top: 28),
                        child: DropdownButton<String>(
                          items: residenceTypes.map((item) {
                            return DropdownMenuItem<String>(
                              value: item,
                              child: Text(
                                item,
                                style: const TextStyle(
                                  fontSize: 21,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (valueItem) {
                            if (valueItem != null &&
                                residenceTypes.contains(valueItem)) {
                              setState(() {
                                residenceTypeSelected = valueItem;
                              });
                            }
                          },
                          isExpanded: true,
                          value: residenceTypeSelected,
                          hint: const Text(
                            "Select property type",
                            style: TextStyle(
                              fontSize: 21,
                            ),
                          ),
                        ),
                      ),

                      //Price /night
                      Padding(
                        padding: const EdgeInsets.only(top: 21),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Expanded(
                              child: TextFormField(
                                decoration:
                                    const InputDecoration(labelText: "Price"),
                                style: const TextStyle(
                                  fontSize: 25.0,
                                ),
                                keyboardType: TextInputType.number,
                                controller: _priceTextEditingController,
                                validator: (text) {
                                  if (text == null || text.isEmpty) {
                                    return "Please Enter Price";
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const Padding(
                              padding:
                                  EdgeInsets.only(left: 10.0, bottom: 10.0),
                              child: Text(
                                " / night",
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      //Description
                      Padding(
                        padding: const EdgeInsets.only(top: 21.0),
                        child: TextFormField(
                          decoration:
                              const InputDecoration(labelText: "Description"),
                          style: const TextStyle(
                            fontSize: 25.0,
                          ),
                          controller: _descriptionTextEditingController,
                          maxLines: 3,
                          minLines: 1,
                          validator: (text) {
                            if (text == null || text.isEmpty) {
                              return "Please Enter Description";
                            }
                            return null;
                          },
                        ),
                      ),

                      //Address
                      Padding(
                        padding: const EdgeInsets.all(21.0),
                        child: TextFormField(
                          decoration:
                              const InputDecoration(labelText: "Address"),
                          maxLines: 3,
                          style: const TextStyle(
                            fontSize: 25.0,
                          ),
                          controller: _addressTextEditingController,
                          validator: (text) {
                            if (text == null || text.isEmpty) {
                              return "Please Enter Address";
                            }
                            return null;
                          },
                        ),
                      ),

                      //Beds
                      const Padding(
                        padding: EdgeInsets.only(top: 38.0),
                        child: Text(
                          'Beds',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      Padding(
                        padding:
                            const EdgeInsets.only(top: 20, left: 20, right: 20),
                        child: Column(
                          children: <Widget>[
                            AmenitiesUI(
                              type: 'Twin/Single',
                              startValue: _beds['small'] ?? 0,
                              decreaseValue: () {
                                setState(() {
                                  _beds['small'] = (_beds['small'] ?? 0) - 1;
                                  if (_beds['small']! < 0) _beds['small'] = 0;
                                });
                              },
                              increaseValue: () {
                                setState(() {
                                  _beds['small'] = (_beds['small'] ?? 0) + 1;
                                });
                              },
                            ),
                            AmenitiesUI(
                              type: 'Double',
                              startValue: _beds['medium'] ?? 0,
                              decreaseValue: () {
                                setState(() {
                                  _beds['medium'] = (_beds['medium'] ?? 0) - 1;
                                  if (_beds['medium']! < 0) _beds['medium'] = 0;
                                });
                              },
                              increaseValue: () {
                                setState(() {
                                  _beds['medium'] = (_beds['medium'] ?? 0) + 1;
                                });
                              },
                            ),
                            AmenitiesUI(
                              type: 'Queen/King',
                              startValue: _beds['large'] ?? 0,
                              decreaseValue: () {
                                setState(() {
                                  _beds['large'] = (_beds['large'] ?? 0) - 1;
                                  if (_beds['large']! < 0) _beds['large'] = 0;
                                });
                              },
                              increaseValue: () {
                                setState(() {
                                  _beds['large'] = (_beds['large'] ?? 0) + 1;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      // Bathrooms
                      const Padding(
                        padding: EdgeInsets.only(top: 20.0),
                        child: Text(
                          'Bathrooms',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 30, 20, 5),
                        child: Column(
                          children: <Widget>[
                            AmenitiesUI(
                              type: 'Full',
                              startValue: _bathrooms['full'] ?? 0,
                              decreaseValue: () {
                                setState(() {
                                  _bathrooms['full'] =
                                      (_bathrooms['full'] ?? 0) - 1;
                                  if (_bathrooms['full']! < 0)
                                    _bathrooms['full'] = 0;
                                });
                              },
                              increaseValue: () {
                                setState(() {
                                  _bathrooms['full'] =
                                      (_bathrooms['full'] ?? 0) + 1;
                                });
                              },
                            ),
                            AmenitiesUI(
                              type: 'Half',
                              startValue: _bathrooms['half'] ?? 0,
                              decreaseValue: () {
                                setState(() {
                                  _bathrooms['half'] =
                                      (_bathrooms['half'] ?? 0) - 1;
                                  if (_bathrooms['half']! < 0)
                                    _bathrooms['half'] = 0;
                                });
                              },
                              increaseValue: () {
                                setState(() {
                                  _bathrooms['half'] =
                                      (_bathrooms['half'] ?? 0) + 1;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      // Extra Amenities
                      Padding(
                        padding: const EdgeInsets.only(top: 21),
                        child: TextFormField(
                          decoration: const InputDecoration(
                              labelText: "Amenities (comma separated)"),
                          style: const TextStyle(
                            fontSize: 25.0,
                          ),
                          controller: _amenitiesTextEditingController,
                          validator: (text) {
                            if (text == null || text.isEmpty) {
                              return "Please enter valid amenities (comma separated)";
                            }
                            return null;
                          },
                          maxLines: 3,
                          minLines: 1,
                        ),
                      ),

                      //Photo
                      Padding(
                        padding: const EdgeInsets.only(top: 21, bottom: 21),
                        child: GridView.builder(
                          shrinkWrap: true,
                          itemCount: _imagesList.length + 1,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 25,
                            crossAxisSpacing: 25,
                            childAspectRatio: 3 / 2,
                          ),
                          itemBuilder: (context, index) {
                            if (index == _imagesList.length) {
                              return IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  _selectImageFromGallery(-1);
                                },
                              );
                            }
                            return MaterialButton(
                              onPressed: () {},
                              child: Image(
                                image: _imagesList[index],
                                fit: BoxFit.fill,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
