import 'package:sua_barbearia/models/plan.dart';
import 'package:flutter_test/flutter_test.dart';

/// Os payloads abaixo reproduzem o formato real devolvido pela API do Sua Barbearia.
void main() {
  group('Plan', () {
    Map<String, dynamic> payload() => {
          'id': 1,
          'uuid': 'plan-uuid',
          'name': 'Barba & Cabelo',
          'description': 'Dois cortes por mês',
          'price': '99.90',
          'overage_discount_percentage': '50.00',
          'pays_barber_commission': true,
          'is_active': true,
          'is_public': true,
          'branch_ids': [1, 2],
          'plan_services': [
            {
              'id': 10,
              'service': 3,
              'service_name': 'Corte Masculino',
              'service_price': '45.00',
              'service_duration_minutes': 30,
              'monthly_quota': 2,
              'is_unlimited': false,
            },
            {
              'id': 11,
              'service': 4,
              'service_name': 'Barba',
              'service_price': '30.00',
              'service_duration_minutes': 20,
              'monthly_quota': 0,
              'is_unlimited': true,
            },
          ],
          'subscribers_count': 7,
        };

    test('desserializa o plano com a composição de serviços', () {
      final plan = Plan.fromJson(payload());

      expect(plan.name, 'Barba & Cabelo');
      expect(plan.price, 99.90);
      expect(plan.overageDiscountPercentage, 50.0);
      expect(plan.hasOverageDiscount, isTrue);
      expect(plan.branchIds, [1, 2]);
      expect(plan.subscribersCount, 7);
      expect(plan.services, hasLength(2));
    });

    test('cota zero é apresentada como ilimitada', () {
      final plan = Plan.fromJson(payload());

      expect(plan.services[0].isUnlimited, isFalse);
      expect(plan.services[0].quotaLabel, '2x por mês');
      expect(plan.services[1].isUnlimited, isTrue);
      expect(plan.services[1].quotaLabel, 'Ilimitado');
    });

    test('aceita `branches` quando o payload não traz `branch_ids`', () {
      // A listagem expõe `branch_ids`; o detalhe expõe `branches`.
      final plan = Plan.fromJson({
        'id': 2,
        'name': 'Simples',
        'price': '50.00',
        'branches': [5],
      });
      expect(plan.branchIds, [5]);
    });

    test('plano sem desconto acima da cota', () {
      final plan = Plan.fromJson({
        'id': 3,
        'name': 'Sem desconto',
        'price': '10.00',
        'overage_discount_percentage': '0.00',
      });
      expect(plan.hasOverageDiscount, isFalse);
    });
  });

  group('BillingType', () {
    test('mapeia os valores da API', () {
      expect(BillingType.fromWire('PIX_MONTHLY'), BillingType.pixMonthly);
      expect(
        BillingType.fromWire('CARD_RECURRING'),
        BillingType.cardRecurring,
      );
      expect(BillingType.cardRecurring.isRecurring, isTrue);
      expect(BillingType.pixMonthly.isRecurring, isFalse);
    });

    test('valor desconhecido não quebra a desserialização', () {
      expect(BillingType.fromWire('BOLETO'), BillingType.unknown);
    });
  });

  group('SubscriptionStatus', () {
    test('identifica os estados que exigem pagamento', () {
      expect(
          SubscriptionStatus.fromWire('PENDING_PAYMENT').needsPayment, isTrue);
      expect(SubscriptionStatus.fromWire('PAST_DUE').needsPayment, isTrue);
      expect(SubscriptionStatus.fromWire('ACTIVE').needsPayment, isFalse);
    });

    test('identifica os estados encerrados', () {
      expect(SubscriptionStatus.fromWire('CANCELLED').isFinished, isTrue);
      expect(SubscriptionStatus.fromWire('EXPIRED').isFinished, isTrue);
      expect(SubscriptionStatus.fromWire('ACTIVE').isFinished, isFalse);
    });
  });

  group('SubscriptionInvoice', () {
    Map<String, dynamic> pixPayload({String? expiresAt}) => {
          'id': 20,
          'subscription': 5,
          'plan_name': 'Barba & Cabelo',
          'amount': '99.90',
          'method': 'PIX',
          'status': 'PENDING',
          'period_start': '2026-09-01',
          'period_end': '2026-09-30',
          'due_date': '2026-09-01',
          'pix_qr_code': '00020126580014br.gov.bcb.pix',
          'pix_qr_code_base64': 'aGVsbG8=',
          'checkout_url': 'https://mp.test/ticket/1',
          'expires_at': expiresAt,
        };

    test('desserializa a cobrança PIX com o QR', () {
      final invoice = SubscriptionInvoice.fromJson(pixPayload());

      expect(invoice.amount, 99.90);
      expect(invoice.isPix, isTrue);
      expect(invoice.isPending, isTrue);
      expect(invoice.hasPixData, isTrue);
      expect(invoice.status, InvoiceStatus.pending);
    });

    test('QR vencido é detectado no cliente', () {
      final expirado = SubscriptionInvoice.fromJson(
        pixPayload(expiresAt: '2020-01-01T10:00:00Z'),
      );
      expect(expirado.isExpired, isTrue);

      final futuro = SubscriptionInvoice.fromJson(
        pixPayload(expiresAt: '2099-01-01T10:00:00Z'),
      );
      expect(futuro.isExpired, isFalse);
    });

    test('sem data de expiração não é considerada vencida', () {
      expect(SubscriptionInvoice.fromJson(pixPayload()).isExpired, isFalse);
    });

    test('cobrança no cartão traz o checkout do provedor', () {
      final invoice = SubscriptionInvoice.fromJson({
        'id': 21,
        'amount': '99.90',
        'method': 'CREDIT_CARD',
        'status': 'PENDING',
        'checkout_url': 'https://mp.test/checkout/preapp-1',
      });

      expect(invoice.isPix, isFalse);
      expect(invoice.checkoutUrl, 'https://mp.test/checkout/preapp-1');
    });
  });

  group('SubscriptionQuota', () {
    test('mostra o restante quando há cota', () {
      final quota = SubscriptionQuota.fromJson({
        'service': 3,
        'service_name': 'Corte',
        'monthly_quota': 4,
        'is_unlimited': false,
        'used': 1,
        'remaining': 3,
      });

      expect(quota.label, '3 de 4 restante(s)');
      expect(quota.progress, closeTo(0.25, 0.001));
    });

    test('cota ilimitada mostra o total usado', () {
      final quota = SubscriptionQuota.fromJson({
        'service': 4,
        'service_name': 'Barba',
        'monthly_quota': 0,
        'is_unlimited': true,
        'used': 6,
        'remaining': null,
      });

      expect(quota.isUnlimited, isTrue);
      expect(quota.label, 'Ilimitado · 6 usado(s)');
      // Sem cota não há barra de progresso a preencher.
      expect(quota.progress, 0);
    });

    test('progresso não passa de 100% se o uso exceder a cota', () {
      final quota = SubscriptionQuota.fromJson({
        'service': 3,
        'service_name': 'Corte',
        'monthly_quota': 2,
        'is_unlimited': false,
        'used': 5,
        'remaining': 0,
      });
      expect(quota.progress, 1.0);
    });
  });

  group('Subscription', () {
    Map<String, dynamic> payload({
      String status = 'ACTIVE',
      Map<String, dynamic>? openInvoice,
    }) =>
        {
          'id': 5,
          'uuid': 'sub-uuid',
          'client': 2,
          'client_name': 'Carlos Mendes',
          'client_phone': '41977770000',
          'plan': 1,
          'plan_detail': {
            'id': 1,
            'name': 'Barba & Cabelo',
            'price': '99.90',
            'plan_services': <Map<String, dynamic>>[],
          },
          'branch': 1,
          'branch_name': 'Sua Barbearia Centro',
          'status': status,
          'billing_type': 'PIX_MONTHLY',
          'price': '99.90',
          'current_period_start': '2026-09-01',
          'current_period_end': '2026-09-30',
          'grants_benefit': status == 'ACTIVE',
          'cancel_at_period_end': false,
          'quotas': [
            {
              'service': 3,
              'service_name': 'Corte',
              'monthly_quota': 2,
              'is_unlimited': false,
              'used': 0,
              'remaining': 2,
            },
          ],
          'open_invoice': openInvoice,
        };

    test('desserializa a assinatura ativa com cota', () {
      final subscription = Subscription.fromJson(payload());

      expect(subscription.status, SubscriptionStatus.active);
      expect(subscription.billingType, BillingType.pixMonthly);
      expect(subscription.planName, 'Barba & Cabelo');
      expect(subscription.grantsBenefit, isTrue);
      expect(subscription.quotas, hasLength(1));
      expect(subscription.currentPeriodEnd?.day, 30);
    });

    test('sem fatura em aberto não há pagamento pendente', () {
      final subscription = Subscription.fromJson(payload());
      expect(subscription.openInvoice, isNull);
      expect(subscription.needsPayment, isFalse);
    });

    test('fatura em aberto sinaliza pagamento pendente', () {
      final subscription = Subscription.fromJson(
        payload(
          status: 'PENDING_PAYMENT',
          openInvoice: {
            'id': 20,
            'amount': '99.90',
            'method': 'PIX',
            'status': 'PENDING',
            'pix_qr_code': '000201',
          },
        ),
      );

      expect(subscription.needsPayment, isTrue);
      expect(subscription.grantsBenefit, isFalse);
      expect(subscription.openInvoice?.amount, 99.90);
    });

    test('nome do plano cai para o id quando o detalhe não vem', () {
      final subscription = Subscription.fromJson({
        'id': 6,
        'plan': 42,
        'status': 'ACTIVE',
        'billing_type': 'PIX_MONTHLY',
        'price': '10.00',
      });
      expect(subscription.plan, isNull);
      expect(subscription.planName, 'Plano #42');
    });
  });
}
