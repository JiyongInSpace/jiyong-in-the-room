import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 공통 입력 필드 스타일 상수
class CommonInputConstants {
  static const double height = 56.0;
  static const double dateFieldHeight = 64.0; // 날짜 필드는 더 높게
  static const EdgeInsets contentPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  static const EdgeInsets dateFieldPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  static const BorderRadius borderRadius = BorderRadius.all(Radius.circular(8));
  static const double borderWidth = 1.0;
  
  // 기본 InputDecoration 테마
  static InputDecoration getInputDecoration({
    required String labelText,
    String? hintText,
    String? helperText,
    String? errorText,
    Widget? suffixIcon,
    Widget? prefixIcon,
    int? maxLines,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      errorText: errorText,
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
      contentPadding: maxLines != null && maxLines > 1 
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 16)
          : contentPadding,
      border: const OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(width: borderWidth),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: Colors.grey.shade400, width: borderWidth),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: Colors.blue, width: borderWidth + 0.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: Colors.red, width: borderWidth),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: Colors.red, width: borderWidth + 0.5),
      ),
      filled: false,
    );
  }
}

/// 공통 텍스트 입력 필드
class CommonTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final String? helperText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final bool enabled;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;

  const CommonTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.helperText,
    this.suffixIcon,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.maxLength,
    this.enabled = true,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    // helperText나 maxLength가 있을 때 높이 조정
    double fieldHeight = CommonInputConstants.height;
    if (helperText != null || maxLength != null) {
      fieldHeight = CommonInputConstants.height + 24; // 추가 공간 확보
    }

    return SizedBox(
      height: fieldHeight,
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        enabled: enabled,
        onTap: onTap,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        focusNode: focusNode,
        validator: validator,
        textCapitalization: textCapitalization,
        decoration: CommonInputConstants.getInputDecoration(
          labelText: labelText,
          hintText: hintText,
          helperText: helperText,
          suffixIcon: suffixIcon,
          prefixIcon: prefixIcon,
        ).copyWith(
          counterText: maxLength != null ? null : "",
        ),
      ),
    );
  }
}

/// 공통 텍스트 영역 (멀티라인)
class CommonTextArea extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final String? helperText;
  final int maxLines;
  final int? maxLength;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;

  const CommonTextArea({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.helperText,
    this.maxLines = 3,
    this.maxLength,
    this.enabled = true,
    this.onChanged,
    this.focusNode,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      enabled: enabled,
      onChanged: onChanged,
      focusNode: focusNode,
      validator: validator,
      decoration: CommonInputConstants.getInputDecoration(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        maxLines: maxLines,
      ).copyWith(
        counterText: maxLength != null ? null : "",
      ),
    );
  }
}

/// 공통 드롭다운 필드
class CommonDropdownField<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final String labelText;
  final String? hintText;
  final String? helperText;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final bool enabled;

  const CommonDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.labelText,
    this.hintText,
    this.helperText,
    this.onChanged,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: CommonInputConstants.height,
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: enabled ? onChanged : null,
        validator: validator,
        decoration: CommonInputConstants.getInputDecoration(
          labelText: labelText,
          hintText: hintText,
          helperText: helperText,
        ),
      ),
    );
  }
}

/// 공통 날짜 선택 필드
class CommonDateField extends StatelessWidget {
  final DateTime? selectedDate;
  final String labelText;
  final VoidCallback onTap;
  final String? helperText;
  final bool enabled;

  const CommonDateField({
    super.key,
    required this.selectedDate,
    required this.labelText,
    required this.onTap,
    this.helperText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final selectedDateStr = selectedDate != null
        ? selectedDate!.toLocal().toString().split(' ')[0]
        : '날짜를 선택하세요';

    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        height: CommonInputConstants.dateFieldHeight,
        padding: CommonInputConstants.dateFieldPadding,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: CommonInputConstants.borderRadius,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    labelText,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedDateStr,
                    style: const TextStyle(fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.calendar_today,
              color: enabled ? Colors.blue : Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// 공통 자동완성 필드
class CommonAutocompleteField<T extends Object> extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final FocusNode? focusNode;
  final Iterable<T> Function(TextEditingValue) optionsBuilder;
  final void Function(T) onSelected;
  final String Function(T) displayStringForOption;
  final Widget Function(BuildContext, void Function(T), Iterable<T>)? optionsViewBuilder;
  final bool enabled;
  final Widget? suffixIcon;

  const CommonAutocompleteField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.optionsBuilder,
    required this.onSelected,
    required this.displayStringForOption,
    this.hintText,
    this.focusNode,
    this.optionsViewBuilder,
    this.enabled = true,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<T>(
      textEditingController: controller,
      focusNode: focusNode ?? FocusNode(),
      optionsBuilder: optionsBuilder,
      onSelected: onSelected,
      displayStringForOption: displayStringForOption,
      optionsViewBuilder: optionsViewBuilder ?? (context, onSelected, options) {
        return Stack(
          children: [
            // 전체 화면을 덮는 투명한 터치 감지 영역
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  // 바깥쪽 클릭 시 포커스 해제하여 옵션박스 닫기
                  FocusScope.of(context).unfocus();
                },
                behavior: HitTestBehavior.translucent,
                child: Container(),
              ),
            ),
            // 실제 옵션 리스트
            Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(displayStringForOption(option)),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return SizedBox(
          height: CommonInputConstants.height,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            decoration: CommonInputConstants.getInputDecoration(
              labelText: labelText,
              hintText: hintText,
              suffixIcon: suffixIcon,
            ),
            onSubmitted: (value) => onFieldSubmitted(),
          ),
        );
      },
    );
  }
}