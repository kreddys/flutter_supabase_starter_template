import 'package:equatable/equatable.dart';
import 'package:amaravati_chamber/core/use_cases/use_case.dart';
import 'package:amaravati_chamber/features/theme_mode/domain/repository/theme_mode_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class SetThemeModeUseCase extends UseCase<void, SetThemeModeUseCaseParams> {
  SetThemeModeUseCase(
    this._themeModeRepository,
  );

  final ThemeModeRepository _themeModeRepository;

  @override
  void execute(SetThemeModeUseCaseParams params) {
    _themeModeRepository.setThemeMode(params.themeModeIndex);
  }
}

class SetThemeModeUseCaseParams extends Equatable {
  const SetThemeModeUseCaseParams({
    required this.themeModeIndex,
  });

  final int themeModeIndex;

  @override
  List<Object?> get props => [
        themeModeIndex,
      ];
}
