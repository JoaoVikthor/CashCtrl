import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'models/budget.dart';
import 'models/transaction.dart';
import 'models/ingredient.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'providers/user_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/ingredient_provider.dart';
import 'providers/product_provider.dart';
import 'screens/login_screen.dart';
import 'screens/cadastro_screen.dart';
import 'screens/transaction_form_screen.dart';
import 'screens/budget_form_screen.dart';
import 'screens/ingredients_screen.dart';
import 'screens/ingredient_form_screen.dart';
import 'screens/products_screen.dart';
import 'screens/product_form_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/ingredient_offers_screen.dart';
import 'screens/offer_form_screen.dart';
import 'screens/audit_logs_screen.dart';
import 'screens/compare_prices_screen.dart';
import 'models/ingredient_offer.dart';
import 'screens/settings/edit_profile_screen.dart';
import 'screens/settings/notifications_screen.dart';
import 'screens/settings/security_screen.dart';
import 'screens/settings/help_screen.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'home_screen.dart';
import 'budgets_screen.dart';
import 'expenses_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const CashCtrlApp());
}

class CashCtrlApp extends StatelessWidget {
  const CashCtrlApp({super.key});

  static bool _notificationsInitialized = false;

  @override
  Widget build(BuildContext context) {
    if (!_notificationsInitialized) {
      _notificationsInitialized = true;
      _initializeNotifications();
    }
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().authStateChanges,
          initialData: null,
        ),
        ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
        ChangeNotifierProvider<TransactionProvider>(
          create: (_) => TransactionProvider(),
        ),
        ChangeNotifierProvider<BudgetProvider>(create: (_) => BudgetProvider()),
        ChangeNotifierProvider<IngredientProvider>(
          create: (_) => IngredientProvider(),
        ),
        ChangeNotifierProvider<ProductProvider>(
          create: (_) => ProductProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'CashCtrl',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/cadastro': (context) => const CadastroScreen(),
          '/dashboard': (context) => const HomeScreen(),
          '/budgets': (context) => const BudgetsScreen(),
          '/budget-form': (context) => BudgetFormScreen(
            editing: ModalRoute.of(context)?.settings.arguments as Budget?,
          ),
          '/expenses': (context) => const ExpensesScreen(),
          '/transaction-form': (context) => TransactionFormScreen(
            editing:
                ModalRoute.of(context)?.settings.arguments as AppTransaction?,
          ),
          '/reports': (context) => const ReportsScreen(),
          '/ingredients': (context) => const IngredientsScreen(),
          '/ingredient-form': (context) => IngredientFormScreen(
            editing: ModalRoute.of(context)?.settings.arguments as Ingredient?,
          ),
          '/products': (context) => const ProductsScreen(),
          '/product-form': (context) {
            final id = ModalRoute.of(context)?.settings.arguments as String?;
            return ProductFormScreen(
              editing: id == null
                  ? null
                  : context
                        .read<ProductProvider>()
                        .list
                        .where((p) => p.id == id)
                        .firstOrNull,
            );
          },
          '/product-detail': (context) => const ProductDetailScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/settings/profile': (context) => const EditProfileScreen(),
          '/settings/notifications': (context) => const NotificationsScreen(),
          '/settings/security': (context) => const SecurityScreen(),
          '/settings/help': (context) => const HelpScreen(),
          '/ingredient-offers': (context) => IngredientOffersScreen(
            ingredientId: ModalRoute.of(context)?.settings.arguments as String,
          ),
          '/offer-form': (context) {
            final map =
                ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
            return OfferFormScreen(
              ingredientId: (map?['ingredientId'] ?? '') as String,
              offer: map?['offer'] as IngredientOffer?,
            );
          },
          '/audit-logs': (context) => const AuditLogsScreen(),
          '/compare-prices': (context) => const ComparePricesScreen(),
        },
        home: const AuthGate(),
      ),
    );
  }

  void _initializeNotifications() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.initialize();
    });
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<User?>? _sub;
  User? _user;
  bool _waiting = true;
  bool _linked = false;

  @override
  void initState() {
    super.initState();
    final AuthService authService = context.read<AuthService>();
    final UserProvider userProvider = context.read<UserProvider>();
    final TransactionProvider txProvider = context.read<TransactionProvider>();
    final BudgetProvider budgetProvider = context.read<BudgetProvider>();
    final IngredientProvider ingredientProvider = context
        .read<IngredientProvider>();
    final ProductProvider productProvider = context.read<ProductProvider>();
    if (!_linked) {
      txProvider.attach(userProvider);
      budgetProvider.attach(userProvider);
      ingredientProvider.attach(userProvider);
      productProvider.attach(userProvider);
      _linked = true;
    }
    _sub = authService.authStateChanges.listen((User? user) {
      if (user == null) {
        userProvider.limpar();
        NotificationService.instance.cancelAll();
      } else {
        userProvider.setUsuario(user.uid);
      }
      if (mounted) setState(() => _user = user);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _waiting) setState(() => _waiting = false);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_waiting) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    if (_user == null) {
      return const LoginScreen();
    }
    return const HomeScreen();
  }
}
