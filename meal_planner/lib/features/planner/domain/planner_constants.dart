abstract final class MealType {
  static const breakfast = 'breakfast';
  static const lunch = 'lunch';
  static const dinner = 'dinner';

  static const all = [breakfast, lunch, dinner];

  static String label(String mealType) => switch (mealType) {
        breakfast => 'Desayuno',
        lunch => 'Comida',
        dinner => 'Cena',
        _ => mealType,
      };
}

abstract final class DayOfWeek {
  static const labels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
}
