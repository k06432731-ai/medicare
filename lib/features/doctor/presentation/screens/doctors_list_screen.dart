import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medicare/core/constants/app_colors.dart';
import 'package:medicare/features/doctor/data/models/doctor_model.dart';
import 'package:medicare/features/doctor/presentation/widgets/doctor_card.dart';
import 'package:medicare/features/doctor/providers/doctor_provider.dart';

class DoctorsListScreen extends ConsumerStatefulWidget {
  const DoctorsListScreen({super.key});

  @override
  ConsumerState<DoctorsListScreen> createState() => _DoctorsListScreenState();
}

class _DoctorsListScreenState extends ConsumerState<DoctorsListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedSpecialty = ref.watch(selectedSpecialtyProvider);
    final doctorsAsync = ref.watch(doctorsProvider(selectedSpecialty));
    final specialtiesAsync = ref.watch(specialtiesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Trouver un médecin'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildSpecialtyFilter(specialtiesAsync),
          Expanded(
            child: doctorsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _buildError(e.toString()),
              data: (doctors) {
                final filtered = _filterDoctors(doctors);
                if (filtered.isEmpty) return _buildEmpty();
                return _buildDoctorsList(filtered);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Nom, spécialité...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildSpecialtyFilter(AsyncValue<List<String>> specialtiesAsync) {
    final selected = ref.watch(selectedSpecialtyProvider);
    return Container(
      height: 44,
      color: Colors.white,
      child: specialtiesAsync.when(
        loading: () => const SizedBox(),
        error: (err, stack) => const SizedBox(),
        data: (specialties) => ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _SpecialtyChip(
              label: 'Tous',
              selected: selected == null,
              onTap: () => ref.read(selectedSpecialtyProvider.notifier).state = null,
            ),
            ...specialties.map((s) => _SpecialtyChip(
                  label: s,
                  selected: selected == s,
                  onTap: () => ref.read(selectedSpecialtyProvider.notifier).state = s,
                )),
          ],
        ),
      ),
    );
  }

  List<DoctorModel> _filterDoctors(List<DoctorModel> doctors) {
    if (_searchQuery.isEmpty) return doctors;
    return doctors.where((d) {
      return d.fullName.toLowerCase().contains(_searchQuery) ||
          (d.specialty?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();
  }

  Widget _buildDoctorsList(List<DoctorModel> doctors) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(doctorsProvider);
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: doctors.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, i) => DoctorCard(
          doctor: doctors[i],
          onBook: () => context.push('/patient/book/${doctors[i].id}', extra: doctors[i]),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text('Aucun médecin trouvé', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(doctorsProvider),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

class _SpecialtyChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SpecialtyChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
