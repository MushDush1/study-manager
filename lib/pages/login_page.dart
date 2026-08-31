import 'package:flutter/material.dart';

import '../services/auth_store.dart';
import '../theme/app_colors.dart';

void openLoginPage(BuildContext context, AuthStore auth, {Future<void> Function()? onCloudLogin}) {
    Navigator.of(context).push(
        MaterialPageRoute(
            builder: (context) => LoginPage(auth: auth, onCloudLogin: onCloudLogin),
        ),
    );
}

class LoginPage extends StatefulWidget {
    final AuthStore auth;
    final Future<void> Function()? onCloudLogin;

    const LoginPage({
        super.key,
        required this.auth,
        this.onCloudLogin,
    });

    @override
    State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();
    bool _isRegister = false;
    bool _cloudMode = true;
    bool _obscure = true;
    bool _busy = false;
    String? _error;

    @override
    void dispose() {
        _emailController.dispose();
        _passwordController.dispose();
        super.dispose();
    }

    Future<void> _submit() async {
        setState(() {
            _busy = true;
            _error = null;
        });

        final result = _cloudMode
            ? (_isRegister
                ? await widget.auth.registerCloud(
                    email: _emailController.text, password: _passwordController.text)
                : await widget.auth.loginCloud(
                    email: _emailController.text, password: _passwordController.text))
            : (_isRegister
            ? await widget.auth.register(
                email: _emailController.text,
                password: _passwordController.text,
            )
            : await widget.auth.login(
                email: _emailController.text,
                password: _passwordController.text));

        if (!mounted) {
            return;
        }

        setState(() {
            _busy = false;
        });

        if (!result.ok) {
            setState(() {
                _error = result.message;
            });
            return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message)),
        );
        if (_cloudMode && widget.onCloudLogin != null) {
            await widget.onCloudLogin!();
        }
        if (!mounted) return;
        Navigator.of(context).pop();
    }

    @override
    Widget build(BuildContext context) {
        return ColoredBox(
            color: AppColors.background,
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Scaffold(
                        backgroundColor: AppColors.background,
                        appBar: AppBar(
                            toolbarHeight: 48,
                            backgroundColor: AppColors.background,
                            foregroundColor: AppColors.text,
                            elevation: 0,
                            title: Text(_isRegister ? (_cloudMode ? '注册云端账号' : '创建本地账号') : (_cloudMode ? '云端登录' : '本地登录')),
                            titleTextStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                            ),
                        ),
                        body: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                            children: [
                                SegmentedButton<bool>(
                                    segments: const [
                                        ButtonSegment(value: true, label: Text('云端账号')),
                                        ButtonSegment(value: false, label: Text('本地模式')),
                                    ],
                                    selected: {_cloudMode},
                                    onSelectionChanged: _busy ? null : (value) => setState(() { _cloudMode = value.first; _error = null; }),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                    _cloudMode ? '云端账号可在其他设备同步学习记录。' : '本地模式只保存到当前设备，不会上传。',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: const [AutofillHints.email],
                                    decoration: const InputDecoration(
                                        labelText: "邮箱",
                                        hintText: "例如 name@example.com",
                                        filled: true,
                                        fillColor: Colors.white,
                                    ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                    controller: _passwordController,
                                    obscureText: _obscure,
                                    autofillHints: const [AutofillHints.password],
                                    onSubmitted: (_) => _submit(),
                                    decoration: InputDecoration(
                                        labelText: "密码",
                                        hintText: "至少 6 位",
                                        filled: true,
                                        fillColor: Colors.white,
                                        suffixIcon: IconButton(
                                            onPressed: () {
                                                setState(() {
                                                    _obscure = !_obscure;
                                                });
                                            },
                                            icon: Icon(
                                                _obscure
                                                    ? Icons.visibility_outlined
                                                    : Icons.visibility_off_outlined,
                                            ),
                                        ),
                                    ),
                                ),
                                if (_error != null) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                        _error!,
                                        style: const TextStyle(
                                            color: AppColors.primaryDark,
                                            fontSize: 13,
                                        ),
                                    ),
                                ],
                                const SizedBox(height: 20),
                                FilledButton(
                                    onPressed: _busy ? null : _submit,
                                    style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        minimumSize: const Size.fromHeight(46),
                                    ),
                                    child: _busy
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                            ),
                                        )
                                        : Text(_isRegister ? "注册并登录" : "登录"),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () {
                                            setState(() {
                                                _isRegister = !_isRegister;
                                                _error = null;
                                            });
                                        },
                                    child: Text(
                                        _isRegister
                                            ? "已有账号？去登录"
                                            : "还没有账号？先注册",
                                    ),
                                ),
                            ],
                        ),
                    ),
                ),
            ),
        );
    }
}
