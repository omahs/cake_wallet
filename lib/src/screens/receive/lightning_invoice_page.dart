import 'package:cake_wallet/src/screens/receive/widgets/lightning_input_form.dart';
import 'package:cake_wallet/themes/extensions/exchange_page_theme.dart';
import 'package:cake_wallet/themes/extensions/keyboard_theme.dart';
import 'package:cake_wallet/anonpay/anonpay_donation_link_info.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/entities/receive_page_option.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/present_receive_option_picker.dart';
import 'package:cake_wallet/src/screens/receive/widgets/anonpay_input_form.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/keyboard_done_button.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/view_model/anon_invoice_page_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/receive_option_view_model.dart';
import 'package:cake_wallet/view_model/lightning_invoice_page_view_model.dart';
import 'package:cake_wallet/view_model/lightning_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/trail_button.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LightningInvoicePage extends BasePage {
  LightningInvoicePage({
    required this.lightningViewModel,
    required this.lightningInvoicePageViewModel,
    required this.receiveOptionViewModel,
  }) : _amountFocusNode = FocusNode() {}

  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final FocusNode _amountFocusNode;

  final LightningViewModel lightningViewModel;
  final LightningInvoicePageViewModel lightningInvoicePageViewModel;
  final ReceiveOptionViewModel receiveOptionViewModel;
  final _formKey = GlobalKey<FormState>();

  bool effectsInstalled = false;

  @override
  bool get gradientAll => true;

  @override
  bool get resizeToAvoidBottomInset => false;

  @override
  bool get extendBodyBehindAppBar => true;

  @override
  AppBarStyle get appBarStyle => AppBarStyle.transparent;

  @override
  void onClose(BuildContext context) => Navigator.popUntil(context, (route) => route.isFirst);

  @override
  Widget middle(BuildContext context) => PresentReceiveOptionPicker(
      receiveOptionViewModel: receiveOptionViewModel, color: titleColor(context));

  @override
  Widget trailing(BuildContext context) => TrailButton(
      caption: S.of(context).clear,
      onPressed: () {
        _formKey.currentState?.reset();
        // lightningViewModel.reset();
      });

  Future<bool> _onNavigateBack(BuildContext context) async {
    onClose(context);
    return false;
  }

  @override
  Widget body(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _setReactions(context));

    return WillPopScope(
      onWillPop: () => _onNavigateBack(context),
      child: KeyboardActions(
        disableScroll: true,
        config: KeyboardActionsConfig(
            keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
            keyboardBarColor: Theme.of(context).extension<KeyboardTheme>()!.keyboardBarColor,
            nextFocus: false,
            actions: [
              KeyboardActionsItem(
                focusNode: _amountFocusNode,
                toolbarButtons: [(_) => KeyboardDoneButton()],
              ),
            ]),
        child: Container(
          color: Theme.of(context).colorScheme.background,
          child: ScrollableWithBottomSection(
            contentPadding: EdgeInsets.only(bottom: 24),
            content: Container(
              decoration: responsiveLayoutUtil.shouldRenderMobileUI
                  ? BoxDecoration(
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context)
                              .extension<ExchangePageTheme>()!
                              .firstGradientTopPanelColor,
                          Theme.of(context)
                              .extension<ExchangePageTheme>()!
                              .secondGradientTopPanelColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    )
                  : null,
              child: Observer(builder: (_) {
                return Padding(
                  padding: EdgeInsets.fromLTRB(24, 120, 24, 0),
                  child: LightningInvoiceForm(
                    descriptionController: _descriptionController,
                    amountController: _amountController,
                    depositAmountFocus: _amountFocusNode,
                    formKey: _formKey,
                    lightningInvoicePageViewModel: lightningInvoicePageViewModel,
                  ),
                );
              }),
            ),
            bottomSectionPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
            bottomSection: Observer(builder: (_) {
              return Column(
                children: <Widget>[
                  // Padding(
                  //   padding: EdgeInsets.only(bottom: 15),
                  //   child: Center(
                  //     child: Text(
                  //       S.of(context).anonpay_description("an invoice", "pay"),
                  //       textAlign: TextAlign.center,
                  //       style: TextStyle(
                  //           color: Theme.of(context)
                  //               .extension<ExchangePageTheme>()!
                  //               .receiveAmountColor,
                  //           fontWeight: FontWeight.w500,
                  //           fontSize: 12),
                  //     ),
                  //   ),
                  // ),
                  LoadingPrimaryButton(
                    text: S.of(context).create_invoice,
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      lightningViewModel.createInvoice(amount: _amountController.text, description: _descriptionController.text);
                      lightningInvoicePageViewModel.setRequestParams(
                        inputAmount: _amountController.text,
                        inputDescription: _descriptionController.text,
                      );
                      lightningInvoicePageViewModel.createInvoice();
                    },
                    color: Theme.of(context).primaryColor,
                    textColor: Colors.white,
                    isLoading: lightningInvoicePageViewModel.state is IsExecutingState,
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  void _setReactions(BuildContext context) {
    if (effectsInstalled) {
      return;
    }

    reaction((_) => receiveOptionViewModel.selectedReceiveOption, (ReceivePageOption option) async {
      switch (option) {
        case ReceivePageOption.lightningInvoice:
          break;
        case ReceivePageOption.lightningOnchain:
          final address = await lightningViewModel.receiveOnchain();
          Navigator.popAndPushNamed(
            context,
            Routes.lightningReceiveOnchain,
            arguments: [address, ReceivePageOption.lightningInvoice],
          );
          break;
        default:
      }
    });

    reaction((_) => lightningInvoicePageViewModel.state, (ExecutionState state) {
      if (state is ExecutedSuccessfullyState) {
        // Navigator.pushNamed(context, Routes.anonPayReceivePage, arguments: state.payload);
        lightningViewModel.createInvoice(
          amount: state.payload["amount"] as String,
          description: state.payload["description"] as String?,
        );
      }

      if (state is ExecutedSuccessfullyState) {
        showPopUp<void>(
            context: context,
            builder: (BuildContext context) {
              return AlertWithOneAction(
                  // alertTitle: S.of(context).invoice_created,
                  alertTitle: "Invoice created TODO",
                  alertContent: state.payload as String,
                  buttonText: S.of(context).ok,
                  buttonAction: () => Navigator.of(context).pop());
            });
      }

      if (state is FailureState) {
        showPopUp<void>(
            context: context,
            builder: (BuildContext context) {
              return AlertWithOneAction(
                  alertTitle: S.of(context).error,
                  alertContent: state.error.toString(),
                  buttonText: S.of(context).ok,
                  buttonAction: () => Navigator.of(context).pop());
            });
      }
    });

    effectsInstalled = true;
  }
}