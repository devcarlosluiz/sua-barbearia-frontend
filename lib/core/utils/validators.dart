/// Validações de formulário (apenas UX — o backend revalida tudo).
class Validators {
  const Validators._();

  static final RegExp _emailPattern =
      RegExp(r'^[\w.!#$%&*+/=?^`{|}~-]+@[\w-]+(\.[\w-]+)+$');

  static String? required(String? value, {String field = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) return '$field é obrigatório.';
    return null;
  }

  static String? email(String? value) {
    final empty = required(value, field: 'O e-mail');
    if (empty != null) return empty;
    if (!_emailPattern.hasMatch(value!.trim())) {
      return 'Informe um e-mail válido.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'A senha é obrigatória.';
    if (value.length < 8) return 'A senha deve ter ao menos 8 caracteres.';
    return null;
  }

  static String? Function(String?) confirmPassword(String Function() original) {
    return (String? value) {
      if (value == null || value.isEmpty) return 'Confirme a senha.';
      if (value != original()) return 'As senhas não conferem.';
      return null;
    };
  }

  static String? phone(String? value, {bool isRequired = true}) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return isRequired ? 'O telefone é obrigatório.' : null;
    }
    if (digits.length < 10 || digits.length > 11) {
      return 'Informe um telefone válido com DDD.';
    }
    return null;
  }

  static String? money(String? value, {bool isRequired = true}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'Informe um valor.' : null;
    }
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null) return 'Informe um valor numérico.';
    if (parsed < 0) return 'O valor não pode ser negativo.';
    return null;
  }

  static String? positiveInteger(String? value, {bool isRequired = true}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'Informe uma quantidade.' : null;
    }
    final parsed = int.tryParse(value);
    if (parsed == null) return 'Informe um número inteiro.';
    if (parsed <= 0) return 'A quantidade deve ser maior que zero.';
    return null;
  }

  static String? cpf(String? value, {bool isRequired = false}) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return isRequired ? 'O CPF é obrigatório.' : null;
    if (digits.length != 11 || RegExp(r'^(\d)\1{10}$').hasMatch(digits)) {
      return 'CPF inválido.';
    }

    int digitAt(int length, int startWeight) {
      var total = 0;
      for (var index = 0; index < length; index++) {
        total += int.parse(digits[index]) * (startWeight - index);
      }
      final remainder = (total * 10) % 11;
      return remainder == 10 ? 0 : remainder;
    }

    if (digitAt(9, 10) != int.parse(digits[9])) return 'CPF inválido.';
    if (digitAt(10, 11) != int.parse(digits[10])) return 'CPF inválido.';
    return null;
  }

  static String? cnpj(String? value, {bool isRequired = false}) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return isRequired ? 'O CNPJ é obrigatório.' : null;
    if (digits.length != 14 || RegExp(r'^(\d)\1{13}$').hasMatch(digits)) {
      return 'CNPJ inválido.';
    }

    int checkDigit(List<int> weights) {
      var total = 0;
      for (var index = 0; index < weights.length; index++) {
        total += int.parse(digits[index]) * weights[index];
      }
      final remainder = total % 11;
      return remainder < 2 ? 0 : 11 - remainder;
    }

    const first = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    const second = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    if (checkDigit(first) != int.parse(digits[12])) return 'CNPJ inválido.';
    if (checkDigit(second) != int.parse(digits[13])) return 'CNPJ inválido.';
    return null;
  }

  static String? zipCode(String? value, {bool isRequired = true}) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return isRequired ? 'O CEP é obrigatório.' : null;
    if (digits.length != 8) return 'O CEP deve ter 8 dígitos.';
    return null;
  }

  /// Encadeia validadores, devolvendo o primeiro erro encontrado.
  static String? Function(String?) compose(
    List<String? Function(String?)> validators,
  ) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
