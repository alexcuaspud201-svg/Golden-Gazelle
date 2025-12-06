import 'package:dr_ai/core/utils/helper/extention.dart';
import 'package:dr_ai/data/model/place_suggetion.dart';
import 'package:dr_ai/controller/maps/maps_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart'; // DISABLED - incompatible with Flutter 3.35.4
import 'package:skeletonizer/skeletonizer.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

import '../../core/utils/theme/color.dart';

// TEMPORARY STUB: This widget has been simplified because material_floating_search_bar_2
// is incompatible with Flutter 3.35.4. Replace with a compatible search widget or
// update the package when a compatible version is available.

class MyFloatingSearchBar extends StatefulWidget {
  const MyFloatingSearchBar({
    super.key,
  });

  @override
  MyFloatingSearchBarState createState() => MyFloatingSearchBarState();
}

class MyFloatingSearchBarState extends State<MyFloatingSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  final Duration _debounceDuration = const Duration(milliseconds: 800);

  void _onQueryChanged(String query) {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    if (query.trim().isNotEmpty) {
      _debounceTimer = Timer(_debounceDuration, () {
        final sessionToken = const Uuid().v4();
        context.bloc<MapsCubit>().getPlaceSuggetions(
            place: query.trim(), sessionToken: sessionToken);
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<PlaceSuggestionModel> _placeSuggestionList = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorManager.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: ColorManager.grey.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search TextField
          TextField(
            controller: _searchController,
            onChanged: _onQueryChanged,
            style: context.textTheme.bodySmall?.copyWith(
              color: ColorManager.black,
            ),
            decoration: InputDecoration(
              hintText: 'Find a hospital...',
              hintStyle: context.textTheme.bodySmall?.copyWith(
                color: ColorManager.black.withOpacity(0.6),
              ),
              prefixIcon: Icon(Icons.search, color: ColorManager.green),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: ColorManager.green),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: ColorManager.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 12.h,
              ),
            ),
          ),
          // Results
          BlocBuilder<MapsCubit, MapsState>(
            builder: (context, state) {
              if (state is MapsLoadedSuggestionsSuccess) {
                _placeSuggestionList = state.placeSuggestionList;
                if (_placeSuggestionList.isEmpty) return const SizedBox.shrink();
                
                return Container(
                  constraints: BoxConstraints(maxHeight: 300.h),
                  child: ListView.builder(
                    padding: EdgeInsets.only(top: 10.h, bottom: 10.h),
                    shrinkWrap: true,
                    itemCount: _placeSuggestionList.length,
                    itemBuilder: (context, index) => Card(
                      color: ColorManager.white,
                      child: ListTile(
                        trailing: Icon(
                          Icons.apartment_rounded,
                          size: 20.r,
                          color: ColorManager.green,
                        ),
                        leading: Icon(
                          Icons.place,
                          size: 20.r,
                          color: ColorManager.green,
                        ),
                        title: Text(
                          _placeSuggestionList[index].mainText,
                          textAlign: TextAlign.center,
                          style: context.textTheme.bodyMedium,
                        ),
                        subtitle: Text(
                          _placeSuggestionList[index].secondaryText,
                          textAlign: TextAlign.center,
                          style: context.textTheme.bodySmall
                              ?.copyWith(color: ColorManager.black),
                        ),
                        onTap: () {
                          final sessionToken = const Uuid().v4();
                          context.bloc<MapsCubit>().getPlaceLocation(
                              placeId: _placeSuggestionList[index].placeId,
                              description: _placeSuggestionList[index].description,
                              sessionToken: sessionToken);
                          _searchController.clear();
                          FocusScope.of(context).unfocus();
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                );
              }
              if (state is MapsLoading) {
                return Padding(
                  padding: EdgeInsets.only(top: 10.h, bottom: 10.h),
                  child: Skeletonizer(
                    enabled: true,
                    effect: ShimmerEffect(
                      baseColor: ColorManager.grey.withOpacity(0.2),
                      highlightColor: ColorManager.white,
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: 3,
                      itemBuilder: (context, index) => Card(
                        color: ColorManager.white,
                        child: ListTile(
                          trailing: Icon(
                            Icons.apartment_rounded,
                            size: 20.r,
                            color: ColorManager.green,
                          ),
                          leading: Icon(
                            Icons.place,
                            size: 20.r,
                            color: ColorManager.green,
                          ),
                          title: const Text(
                            "Hospital Name",
                            textAlign: TextAlign.center,
                          ),
                          subtitle: const Text(
                            "Hospital Address, City, Country",
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
