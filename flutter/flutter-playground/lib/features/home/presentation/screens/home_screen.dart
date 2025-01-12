import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_playground/core/service_locator.dart';
import 'package:flutter_playground/core/utils/strings.dart';
import 'package:flutter_playground/core/widgets/custom_text_button.dart';
import 'package:flutter_playground/features/home/domain/entities/account.dart';
import 'package:flutter_playground/features/home/domain/repositories/chain_config_repostiory.dart';
import 'package:flutter_playground/features/home/presentation/provider/home_provider.dart';
import 'package:flutter_playground/features/home/presentation/screens/smart_contract_interaction_screen.dart';
import 'package:flutter_playground/features/home/presentation/screens/transactions_screen.dart';
import 'package:flutter_playground/features/home/presentation/widgets/account_details.dart';
import 'package:flutter_playground/features/home/presentation/widgets/balance_widget.dart';
import 'package:flutter_playground/core/widgets/drawer.dart';
import 'package:flutter_playground/features/home/presentation/widgets/chain_switcher_tile.dart';
import 'package:flutter_playground/features/home/presentation/widgets/home_header.dart';
import 'package:provider/provider.dart';
import 'package:web3auth_flutter/output.dart';
import 'package:web3auth_flutter/web3auth_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ChainConfigRepository chainConfigRepository;
  late final TorusUserInfo userInfo;

  late final StreamController<Account> streamController;
  late final HomeProvider homeProvider;

  @override
  void initState() {
    super.initState();
    chainConfigRepository = ServiceLocator.getIt<ChainConfigRepository>();

    streamController = StreamController<Account>();
    homeProvider = Provider.of<HomeProvider>(
      context,
      listen: false,
    );
    loadAccount(false);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> loadAccount(bool isReload) async {
    if (!isReload) {
      userInfo = await Web3AuthFlutter.getUserInfo();
    }
    final account = await chainConfigRepository.prepareAccount(
      homeProvider.selectedChain,
    );

    homeProvider.updateChainAddress(account.publicAddress);
    streamController.add(account);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(StringConstants.appBarTitle),
      ),
      drawer: const SideDrawer(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        child: StreamBuilder<Account>(
          stream: streamController.stream,
          builder: (context, snapShot) {
            if (snapShot.connectionState == ConnectionState.active) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    const HomeHeader(),
                    const SizedBox(height: 12),
                    ChainSwitchTile(
                      onSelect: (chainConfig) {
                        homeProvider.updateSelectedChain(chainConfig);
                        loadAccount(true);
                      },
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    AccountDetails(
                      userInfo: userInfo,
                      account: snapShot.requireData,
                    ),
                    const SizedBox(height: 24),
                    Consumer<HomeProvider>(builder: (
                      _,
                      homeProvider,
                      __,
                    ) {
                      final chain = homeProvider.selectedChain;
                      return BalanceWidget(
                        balance: snapShot.data!.balance,
                        ticker: chain.ticker,
                        chainId: chain.chainId,
                      );
                    }),
                    const SizedBox(height: 16),
                    Consumer<HomeProvider>(builder: (_, __, ___) {
                      return Column(
                        children: [
                          CustomTextButton(
                              onTap: () {
                                _navigationToScreen(
                                  context,
                                  const TransactionsScreen(),
                                );
                              },
                              text: 'Transaction'),
                          if (homeProvider.selectedChain.isEVMChain) ...[
                            const SizedBox(height: 16),
                            CustomTextButton(
                              onTap: () {
                                _navigationToScreen(
                                  context,
                                  const SmartContractInteractionScreen(),
                                );
                              },
                              text:
                                  StringConstants.smartContractInteractionsText,
                            ),
                          ]
                        ],
                      );
                    }),
                  ],
                ),
              );
            }
            return const Center(child: CircularProgressIndicator.adaptive());
          },
        ),
      ),
    );
  }

  void _navigationToScreen(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) {
      return screen;
    }));
  }
}
