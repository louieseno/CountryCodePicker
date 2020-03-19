library country_code_picker;

import 'package:country_code_picker/country_code.dart';
import 'package:country_code_picker/country_codes.dart';
import 'package:country_code_picker/selection_dialog.dart';
import 'package:flutter/material.dart';

export 'country_code.dart';

class CountryCodePicker extends StatefulWidget {
  final ValueChanged<CountryCode> onChanged;
  final ValueChanged<CountryCode> onInit;
  final String initialSelection;
  final List<String> favorite;
  final TextStyle textStyle;
  final EdgeInsetsGeometry padding;
  final bool showCountryOnly;
  final InputDecoration searchDecoration;
  final TextStyle searchStyle;
  final WidgetBuilder emptySearchBuilder;
  final Function(CountryCode) builder;
  final bool enabled;
  final TextOverflow textOverflow;

  /// shows the name of the country instead of the dialcode
  final bool showOnlyCountryWhenClosed;

  /// aligns the flag and the Text left
  ///
  /// additionally this option also fills the available space of the widget.
  /// this is especially useful in combination with [showOnlyCountryWhenClosed],
  /// because longer country names are displayed in one line
  final bool alignLeft;

  /// shows the flag
  final bool showFlag;

  final bool showFlagMain;

  final bool showFlagDialog;

  /// contains the country codes to load only the specified countries.
  final List<String> countryFilter;

  /// Width of the flag images
  final double flagWidth;

  /// Use this property to change the order of the options
  final Comparator<CountryCode> comparator;

  /// Use border
  final bool border;
  final double borderRadius;
  final double borderWidth;
  final double borderHeight;
  /// Use Icon
  final bool icon;
  final double iconSize;

  CountryCodePicker({
    this.onChanged,
    this.onInit,
    this.initialSelection,
    this.favorite = const [],
    this.countryFilter = const [],
    this.textStyle,
    this.padding = const EdgeInsets.all(0.0),
    this.showCountryOnly = false,
    this.searchDecoration = const InputDecoration(),
    this.searchStyle,
    this.emptySearchBuilder,
    this.showOnlyCountryWhenClosed = false,
    this.alignLeft = false,
    this.showFlag = true,
    this.showFlagDialog,
    this.showFlagMain,
    this.builder,
    this.flagWidth = 32.0,
    this.enabled = true,
    this.textOverflow = TextOverflow.ellipsis,
    this.comparator,
    this.border,
    this.borderRadius,
    this.borderWidth,
    this.borderHeight,
    this.icon,
    this.iconSize,
  });

  @override
  State<StatefulWidget> createState() {
    List<Map> jsonList = codes;

    List<CountryCode> elements =
    jsonList.map((json) => CountryCode.fromJson(json)).toList();

    if (comparator != null) {
      elements.sort(comparator);
    }

    if (countryFilter.length > 0) {
      elements = elements.where((c) => countryFilter.contains(c.code)).toList();
    }

    return _CountryCodePickerState(elements);
  }
}

class _CountryCodePickerState extends State<CountryCodePicker> {
  CountryCode selectedItem;
  List<CountryCode> elements = [];
  List<CountryCode> favoriteElements = [];

  _CountryCodePickerState(this.elements);

  @override
  Widget build(BuildContext context) {
    Widget _widget;
    if (widget.builder != null)
      _widget = InkWell(
        onTap: _showSelectionDialog,
        child: widget.builder(selectedItem.localize(context)),
      );
    else {
      _widget =
      widget.border == true ? Container(
        width: widget.borderWidth??400,
        height: widget.borderHeight??50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
              color: Color(0xFFD1D1D1), style: BorderStyle.solid),
        ),
        child: _buildButton(),
      ): _buildButton();
    }
    return _widget;
  }

  @override
  void didUpdateWidget(CountryCodePicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    _onInit(selectedItem);

    if (oldWidget.initialSelection != widget.initialSelection) {
      if (widget.initialSelection != null) {
        selectedItem = elements.firstWhere(
                (e) =>
            (e.code.toUpperCase() ==
                widget.initialSelection.toUpperCase()) ||
                (e.dialCode == widget.initialSelection.toString()),
            orElse: () => elements[0]);
      } else {
        selectedItem = elements[0];
      }
    }
  }
  Widget _buildButton() => FlatButton(
    onPressed: widget.enabled ? _showSelectionDialog : null,
    padding: widget.padding,
    child: Row(
      children: <Widget>[
        if (widget.showFlag || (widget.showFlagMain == true))
          Flexible(
            flex: widget.alignLeft ? 0 : 1,
            fit: widget.alignLeft ? FlexFit.tight : FlexFit.loose,
            child: Padding(
              padding: widget.alignLeft
                  ? const EdgeInsets.only(right: 16.0, left: 8.0)
                  : const EdgeInsets.only(right: 16.0),
              child: Image.asset(
                selectedItem.flagUri,
                package: 'country_code_picker',
                width: widget.flagWidth,
              ),
            ),
          ),
        Flexible(
          fit: widget.alignLeft ? FlexFit.tight : FlexFit.loose,
          child: Text(
            widget.showOnlyCountryWhenClosed
                ? selectedItem.toCountryStringOnly(context)
                : selectedItem.toString(),
            style: widget.textStyle ?? Theme.of(context).textTheme.button,
            overflow: widget.textOverflow,
          ),
        ),
        widget.icon == true? Icon(Icons.arrow_drop_down, color: Color(0xFF026178), size: widget.iconSize ?? 34): Container(),
      ],
    ),
  );

  @override
  initState() {
    if (widget.initialSelection != null) {
      selectedItem = elements.firstWhere(
              (e) =>
          (e.code.toUpperCase() == widget.initialSelection.toUpperCase()) ||
              (e.dialCode == widget.initialSelection.toString()),
          orElse: () => elements[0]);
    } else {
      selectedItem = elements[0];
    }

    favoriteElements = elements
        .where((e) =>
    widget.favorite.firstWhere(
            (f) => e.code == f.toUpperCase() || e.dialCode == f.toString(),
        orElse: () => null) !=
        null)
        .toList();
    super.initState();
  }

  void _showSelectionDialog() {
    showDialog(
      context: context,
      builder: (_) => SelectionDialog(
        elements,
        favoriteElements,
        showCountryOnly: widget.showCountryOnly,
        emptySearchBuilder: widget.emptySearchBuilder,
        searchDecoration: widget.searchDecoration,
        searchStyle: widget.searchStyle,
        showFlag: widget.showFlag || (widget.showFlagDialog == true),
        flagWidth: widget.flagWidth,
      ),
    ).then((e) {
      if (e != null) {
        setState(() {
          selectedItem = e;
        });

        _publishSelection(e);
      }
    });
  }

  void _publishSelection(CountryCode e) {
    if (widget.onChanged != null) {
      widget.onChanged(e.localize(context));
    }
  }

  void _onInit(CountryCode e) {
    if (widget.onInit != null) {
      widget.onInit(e.localize(context));
    }
  }
}
