import 'package:dr_ai/core/utils/helper/extention.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../controller/medical_tips/medical_tips_cubit.dart';
import '../../core/utils/theme/color.dart';

class MedicalTipCard extends StatefulWidget {
  const MedicalTipCard({
    super.key,
  });

  @override
  State<MedicalTipCard> createState() => _MedicalTipCardState();
}

class _MedicalTipCardState extends State<MedicalTipCard> {
  @override
  void initState() {
    super.initState();
    context.read<MedicalTipsCubit>().fetchDailyTip();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MedicalTipsCubit, MedicalTipsState>(
      builder: (context, state) {
        return _buildCard(state);
      },
    );
  }

  Widget _buildCard(MedicalTipsState state) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: ColorManager.grey.withOpacity(0.3), width: 0.5),
      ),
      color: ColorManager.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _buildContent(state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(MedicalTipsState state) {
    if (state is MedicalTipsLoading) {
      return Skeletonizer(
        enabled: true,
        effect: ShimmerEffect(
          baseColor: ColorManager.grey.withOpacity(0.2),
          highlightColor: ColorManager.grey.withOpacity(0.4),
        ),
        child: _buildTipContent(
          title: "Consejo Médico",
          content:
              "Cargando consejo médico para su salu...",
        ),
      );
    } else if (state is MedicalTipsError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader("Consejos Médicos"),
          const Gap(8),
          Text(
            "Error al cargar consejos médicos. Por favor intente más tarde.",
            style:
                context.textTheme.bodySmall?.copyWith(color: ColorManager.black),
          ),
        ],
      );
    } else if (state is MedicalTipsLoaded) {
      return _buildTipContent(
        title: state.medicalTip.title,
        content: state.medicalTip.content,
      );
    } else {
      return _buildTipContent(
        title: "Consejos Médicos",
        content:
            "Manténgase al día con los últimos consejos médicos para un estilo de vida saludable.",
      );
    }
  }

  Widget _buildTipContent({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(title),
        const Gap(8),
        Text(
          content,
          style: context.textTheme.bodySmall?.copyWith(color: ColorManager.black),
          maxLines: 10,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildHeader(String title) {
    return Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: ColorManager.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(
            Icons.medical_services,
            color: ColorManager.green,
            size: 20,
          ),
        ),
        const Gap(8),
        Expanded(
          child: Text(
            title,
            style: context.textTheme.displayLarge?.copyWith(
              fontSize: 16.sp,
            ),
          ),
        ),
      ],
    );
  }
}
