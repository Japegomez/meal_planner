import 'package:image_picker/image_picker.dart';

int _formItemKeyCounter = 0;
String _newFormItemKey(String prefix) => '$prefix-${_formItemKeyCounter++}';

class IngredientFormItem {
  IngredientFormItem({
    String? key,
    this.name = '',
    this.quantity,
    this.unit,
    this.category = 'Carnes y pescados',
    this.customUnit = '',
    this.useCustomUnit = false,
  }) : key = key ?? _newFormItemKey('ingredient');

  final String key;
  String name;
  num? quantity;
  String? unit;
  String category;
  String customUnit;
  bool useCustomUnit;

  String? get effectiveUnit =>
      useCustomUnit ? (customUnit.trim().isEmpty ? null : customUnit.trim()) : unit;

  IngredientFormItem copyWith({
    String? name,
    num? quantity,
    String? unit,
    String? category,
    String? customUnit,
    bool? useCustomUnit,
  }) {
    return IngredientFormItem(
      key: key,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      customUnit: customUnit ?? this.customUnit,
      useCustomUnit: useCustomUnit ?? this.useCustomUnit,
    );
  }
}

class StepFormItem {
  StepFormItem({String? key, this.description = ''})
      : key = key ?? _newFormItemKey('step');

  final String key;
  String description;
}

class NutritionFormData {
  NutritionFormData({
    this.calories,
    this.protein,
    this.carbohydrates,
    this.fat,
    this.fiber,
  });

  num? calories;
  num? protein;
  num? carbohydrates;
  num? fat;
  num? fiber;

  bool get hasAnyValue =>
      calories != null ||
      protein != null ||
      carbohydrates != null ||
      fat != null ||
      fiber != null;
}

class RecipeFormData {
  RecipeFormData({
    this.title = '',
    this.servings = 4,
    this.prepTime,
    this.cookTime,
    List<String>? tags,
    List<IngredientFormItem>? ingredients,
    List<StepFormItem>? steps,
    NutritionFormData? nutrition,
    this.existingPhotoPath,
    this.removePhoto = false,
    this.pendingPhoto,
    this.isPublic = false,
  })  : tags = tags ?? [],
        ingredients = ingredients ?? [IngredientFormItem()],
        steps = steps ?? [StepFormItem()],
        nutrition = nutrition ?? NutritionFormData();

  String title;
  int servings;
  int? prepTime;
  int? cookTime;
  final List<String> tags;
  final List<IngredientFormItem> ingredients;
  final List<StepFormItem> steps;
  final NutritionFormData nutrition;
  String? existingPhotoPath;
  bool removePhoto;
  XFile? pendingPhoto;
  bool isPublic;

  String? validate() {
    if (title.trim().isEmpty) return 'El nombre es obligatorio';
    if (servings < 1) return 'Las raciones deben ser al menos 1';
    final validIngredients =
        ingredients.where((i) => i.name.trim().isNotEmpty).toList();
    if (validIngredients.isEmpty) {
      return 'Añade al menos un ingrediente';
    }
    return null;
  }

  List<IngredientFormItem> get validIngredients => ingredients
      .where((ingredient) => ingredient.name.trim().isNotEmpty)
      .toList();

  List<StepFormItem> get validSteps =>
      steps.where((step) => step.description.trim().isNotEmpty).toList();
}
