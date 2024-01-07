import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'settings_controller.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key, required this.controller});

  static const routeName = '/settings';

  final SettingsController controller;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  final _tokenController = TextEditingController();
  var _issuePreffixController = TextEditingController();
  var _jiraPathController = TextEditingController();

  late bool _isVisiblePassword = false;
  late bool _isTokenSelected = true;
  final _textControllers = [];
  int inputs = 1;
  String _version = "";

  @override
  void initState() {
    _textControllers.add(_userController);
    _textControllers.add(_passwordController);
    _textControllers.add(_tokenController);
    _issuePreffixController =
        TextEditingController(text: widget.controller.issuePreffix ?? "");
    _jiraPathController =
        TextEditingController(text: widget.controller.jiraPath ?? "");
    _getAppVersion();
    super.initState();
  }

  @override
  void dispose() {
    for (var controller in _textControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    await widget.controller.savePreferences(
        _userController.text,
        _passwordController.text,
        _tokenController.text,
        _issuePreffixController.text,
        _jiraPathController.text);
    await widget.controller.loadSettings();
    _clearTextControllers();
  }

  void _clearTextControllers() {
    for (var controller in _textControllers) {
      controller.clear();
    }
  }

  void _getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      if (mounted) {
        _version = packageInfo.version;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final MaterialStateProperty<Icon?> thumbIcon =
        MaterialStateProperty.resolveWith<Icon?>(
      (Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          return const Icon(Icons.check);
        }
        return const Icon(Icons.close);
      },
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.settings,
        ),
      ),
      body: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(children: [
            SizedBox(
              //width: 250,
              child: TextField(
                keyboardType: TextInputType.text,
                controller: _userController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: AppLocalizations.of(context)?.user,
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            SwitchListTile(
                thumbIcon: thumbIcon,
                value: _isTokenSelected,
                onChanged: (bool value) {
                  setState(() {
                    _isTokenSelected = value;
                  });
                },
                title: Text(AppLocalizations.of(context)!.useToken.toString()),
                subtitle: Text(AppLocalizations.of(context)!
                    .useTokenDescription
                    .toString())),
            const SizedBox(height: 24.0),
            if (!_isTokenSelected)
              SizedBox(
                child: TextField(
                  obscureText: !_isVisiblePassword,
                  controller: _passwordController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: AppLocalizations.of(context)?.password,
                    suffixIcon: IconButton(
                      icon: Icon(_isVisiblePassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () {
                        setState(
                          () {
                            _isVisiblePassword = !_isVisiblePassword;
                          },
                        );
                      },
                    ),
                    alignLabelWithHint: false,
                  ),
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.done,
                ),
              ),
            if (_isTokenSelected)
              SizedBox(
                child: TextField(
                  obscureText: !_isVisiblePassword,
                  controller: _tokenController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: "Token",
                    suffixIcon: IconButton(
                      icon: Icon(_isVisiblePassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () {
                        setState(
                          () {
                            _isVisiblePassword = !_isVisiblePassword;
                          },
                        );
                      },
                    ),
                    alignLabelWithHint: false,
                  ),
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.done,
                ),
              ),
            const SizedBox(height: 24.0),
            SizedBox(
              child: TextField(
                keyboardType: TextInputType.url,
                controller: _jiraPathController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: 'https://jira.domain.com/',
                  labelText: AppLocalizations.of(context)?.jiraPath,
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            SizedBox(
              child: TextField(
                keyboardType: TextInputType.text,
                controller: _issuePreffixController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: AppLocalizations.of(context)?.issuePreffix,
                ),
              ),
            ),
            const SizedBox(height: 30.0),
            DropdownButtonFormField<ThemeMode>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              value: widget.controller.themeMode,
              isExpanded: false,
              borderRadius: BorderRadius.circular(5),
              onChanged: widget.controller.updateThemeMode,
              items: [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text(AppLocalizations.of(context)!.systemTheme),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text(AppLocalizations.of(context)!.lightTheme),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text(AppLocalizations.of(context)!.darkTheme),
                )
              ],
            ),
            const SizedBox(height: 16.0),
            if (_version.isNotEmpty)
              InputChip(
                  avatar: const Icon(Icons.lock_outline_rounded),
                  onSelected: (bool value) {},
                  label: Text("v.$_version")),
            const SizedBox(height: 16.0),
            if (widget.controller.isAuthSaved)
              SizedBox(
                  child: InputChip(
                avatar: const Icon(Icons.check),
                onSelected: (bool value) {},
                label: Text(
                    AppLocalizations.of(context)!.authoritazionSaved.toString(),
                    style: const TextStyle(color: Colors.black)),
                backgroundColor: Colors.greenAccent,
                selectedColor: Colors.black,
              )),
          ])),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: Container(
          height: 50.0,
        ),
      ),
      floatingActionButton: Container(
          margin: const EdgeInsets.all(10),
          child: FloatingActionButton(
              onPressed: _save,
              heroTag: 'save',
              child: const Icon(Icons.save))),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndDocked,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
    );
  }
}
