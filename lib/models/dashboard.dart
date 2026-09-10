import 'appointment.dart';
import 'barber.dart';
import 'branch.dart';
import 'json_utils.dart';
import 'service.dart';

/// Ponto genérico usado pelos gráficos (rótulo + valor + contagem).
class ChartPoint {
  const ChartPoint({
    required this.label,
    required this.value,
    this.count = 0,
    this.secondaryValue = 0,
    this.date,
  });

  final String label;
  final double value;
  final int count;
  final double secondaryValue;
  final DateTime? date;
}

class OwnerDashboard {
  const OwnerDashboard({
    required this.startDate,
    required this.endDate,
    required this.revenueToday,
    required this.revenueMonth,
    required this.revenuePeriod,
    required this.expensePeriod,
    required this.balancePeriod,
    required this.appointmentsToday,
    required this.appointmentsPeriod,
    required this.completedAppointments,
    required this.cancelledAppointments,
    required this.noShowAppointments,
    required this.averageTicket,
    required this.totalClients,
    required this.newClients,
    required this.productsSold,
    required this.productsRevenue,
    required this.pendingCommissions,
    this.revenueByDay = const [],
    this.appointmentsByDay = const [],
    this.topServices = const [],
    this.topBarbers = const [],
    this.revenueByBranch = const [],
    this.paymentMethods = const [],
    this.expensesByCategory = const [],
  });

  final DateTime startDate;
  final DateTime endDate;

  final double revenueToday;
  final double revenueMonth;
  final double revenuePeriod;
  final double expensePeriod;
  final double balancePeriod;
  final int appointmentsToday;
  final int appointmentsPeriod;
  final int completedAppointments;
  final int cancelledAppointments;
  final int noShowAppointments;
  final double averageTicket;
  final int totalClients;
  final int newClients;
  final int productsSold;
  final double productsRevenue;
  final double pendingCommissions;

  final List<ChartPoint> revenueByDay;
  final List<ChartPoint> appointmentsByDay;
  final List<ChartPoint> topServices;
  final List<ChartPoint> topBarbers;
  final List<ChartPoint> revenueByBranch;
  final List<ChartPoint> paymentMethods;
  final List<ChartPoint> expensesByCategory;

  /// Percentual de cancelamento no período.
  double get cancellationRate => appointmentsPeriod == 0
      ? 0
      : (cancelledAppointments / appointmentsPeriod) * 100;

  double get noShowRate => appointmentsPeriod == 0
      ? 0
      : (noShowAppointments / appointmentsPeriod) * 100;

  factory OwnerDashboard.fromJson(Map<String, dynamic> json) {
    final period = Json.asMap(json['period']);
    final kpis = Json.asMap(json['kpis']);
    final charts = Json.asMap(json['charts']);

    return OwnerDashboard(
      startDate: Json.asDate(period['start_date']) ?? DateTime.now(),
      endDate: Json.asDate(period['end_date']) ?? DateTime.now(),
      revenueToday: Json.asDouble(kpis['revenue_today']),
      revenueMonth: Json.asDouble(kpis['revenue_month']),
      revenuePeriod: Json.asDouble(kpis['revenue_period']),
      expensePeriod: Json.asDouble(kpis['expense_period']),
      balancePeriod: Json.asDouble(kpis['balance_period']),
      appointmentsToday: Json.asInt(kpis['appointments_today']),
      appointmentsPeriod: Json.asInt(kpis['appointments_period']),
      completedAppointments: Json.asInt(kpis['completed_appointments']),
      cancelledAppointments: Json.asInt(kpis['cancelled_appointments']),
      noShowAppointments: Json.asInt(kpis['no_show_appointments']),
      averageTicket: Json.asDouble(kpis['average_ticket']),
      totalClients: Json.asInt(kpis['total_clients']),
      newClients: Json.asInt(kpis['new_clients']),
      productsSold: Json.asInt(kpis['products_sold']),
      productsRevenue: Json.asDouble(kpis['products_revenue']),
      pendingCommissions: Json.asDouble(kpis['pending_commissions']),
      revenueByDay: Json.asMapList(charts['revenue_by_day'])
          .map(
            (item) => ChartPoint(
              label: Json.asString(item['date']),
              value: Json.asDouble(item['total']),
              date: Json.asDate(item['date']),
            ),
          )
          .toList(),
      appointmentsByDay: Json.asMapList(charts['appointments_by_day'])
          .map(
            (item) => ChartPoint(
              label: Json.asString(item['date']),
              value: Json.asDouble(item['total']),
              count: Json.asInt(item['completed']),
              secondaryValue: Json.asDouble(item['cancelled']),
              date: Json.asDate(item['date']),
            ),
          )
          .toList(),
      topServices: Json.asMapList(charts['top_services'])
          .map(
            (item) => ChartPoint(
              label: Json.asString(item['service__name']),
              value: Json.asDouble(item['revenue']),
              count: Json.asInt(item['count']),
            ),
          )
          .toList(),
      topBarbers: Json.asMapList(charts['top_barbers'])
          .map(
            (item) => ChartPoint(
              label:
                  Json.asStringOrNull(item['barber__nickname'])?.isNotEmpty ==
                          true
                      ? Json.asString(item['barber__nickname'])
                      : Json.asString(item['barber__user__first_name']),
              value: Json.asDouble(item['revenue']),
              count: Json.asInt(item['count']),
            ),
          )
          .toList(),
      revenueByBranch: Json.asMapList(charts['revenue_by_branch'])
          .map(
            (item) => ChartPoint(
              label: Json.asString(item['branch__name']),
              value: Json.asDouble(item['revenue']),
              count: Json.asInt(item['count']),
            ),
          )
          .toList(),
      paymentMethods: Json.asMapList(charts['payment_methods'])
          .map(
            (item) => ChartPoint(
              label: _paymentLabel(Json.asString(item['method'])),
              value: Json.asDouble(item['total']),
              count: Json.asInt(item['count']),
            ),
          )
          .toList(),
      expensesByCategory: Json.asMapList(charts['expenses_by_category'])
          .map(
            (item) => ChartPoint(
              label: _categoryLabel(Json.asString(item['category'])),
              value: Json.asDouble(item['total']),
            ),
          )
          .toList(),
    );
  }

  static String _paymentLabel(String value) {
    const labels = {
      'PIX': 'PIX',
      'CASH': 'Dinheiro',
      'CREDIT_CARD': 'Crédito',
      'DEBIT_CARD': 'Débito',
      'LOYALTY': 'Pontos',
      'OTHER': 'Outro',
    };
    return labels[value] ?? value;
  }

  static String _categoryLabel(String value) {
    const labels = {
      'SERVICES': 'Serviços',
      'PRODUCTS': 'Produtos',
      'SALARY': 'Salários',
      'COMMISSION': 'Comissões',
      'RENT': 'Aluguel',
      'ELECTRICITY': 'Energia',
      'WATER': 'Água',
      'INTERNET': 'Internet',
      'SUPPLIES': 'Insumos',
      'MARKETING': 'Marketing',
      'TAXES': 'Impostos',
      'OTHER': 'Outros',
    };
    return labels[value] ?? value;
  }
}

class BarberDashboard {
  const BarberDashboard({
    required this.appointmentsToday,
    required this.completedToday,
    required this.revenueToday,
    required this.appointmentsMonth,
    required this.revenueMonth,
    required this.commissionMonth,
    required this.commissionPending,
    required this.commissionPaid,
    required this.rating,
    required this.reviewsCount,
    required this.clientsServed,
    this.revenueByDay = const [],
    this.topServices = const [],
    this.todayAgenda = const [],
    this.nextClients = const [],
  });

  final int appointmentsToday;
  final int completedToday;
  final double revenueToday;
  final int appointmentsMonth;
  final double revenueMonth;
  final double commissionMonth;
  final double commissionPending;
  final double commissionPaid;
  final double rating;
  final int reviewsCount;
  final int clientsServed;
  final List<ChartPoint> revenueByDay;
  final List<ChartPoint> topServices;
  final List<Appointment> todayAgenda;
  final List<Appointment> nextClients;

  factory BarberDashboard.fromJson(Map<String, dynamic> json) {
    final kpis = Json.asMap(json['kpis']);
    final charts = Json.asMap(json['charts']);

    return BarberDashboard(
      appointmentsToday: Json.asInt(kpis['appointments_today']),
      completedToday: Json.asInt(kpis['completed_today']),
      revenueToday: Json.asDouble(kpis['revenue_today']),
      appointmentsMonth: Json.asInt(kpis['appointments_month']),
      revenueMonth: Json.asDouble(kpis['revenue_month']),
      commissionMonth: Json.asDouble(kpis['commission_month']),
      commissionPending: Json.asDouble(kpis['commission_pending']),
      commissionPaid: Json.asDouble(kpis['commission_paid']),
      rating: Json.asDouble(kpis['rating']),
      reviewsCount: Json.asInt(kpis['reviews_count']),
      clientsServed: Json.asInt(kpis['clients_served']),
      revenueByDay: Json.asMapList(charts['revenue_by_day'])
          .map(
            (item) => ChartPoint(
              label: Json.asString(item['date']),
              value: Json.asDouble(item['total']),
              count: Json.asInt(item['count']),
              date: Json.asDate(item['date']),
            ),
          )
          .toList(),
      topServices: Json.asMapList(charts['top_services'])
          .map(
            (item) => ChartPoint(
              label: Json.asString(item['service__name']),
              value: Json.asDouble(item['revenue']),
              count: Json.asInt(item['count']),
            ),
          )
          .toList(),
      todayAgenda: Json.asMapList(json['today_agenda'])
          .map(Appointment.fromJson)
          .toList(),
      nextClients: Json.asMapList(json['next_clients'])
          .map(Appointment.fromJson)
          .toList(),
    );
  }
}

class ClientDashboard {
  const ClientDashboard({
    required this.totalVisits,
    required this.totalSpent,
    required this.averageTicket,
    required this.loyaltyPoints,
    required this.upcomingCount,
    required this.pendingReviews,
    required this.reviewsGiven,
    this.lastVisitAt,
    this.nextAppointment,
    this.preferredBranch,
    this.preferredBarber,
    this.favoriteService,
    this.averageRatingGiven = 0,
  });

  final int totalVisits;
  final double totalSpent;
  final double averageTicket;
  final int loyaltyPoints;
  final int upcomingCount;
  final int pendingReviews;
  final int reviewsGiven;
  final DateTime? lastVisitAt;
  final Appointment? nextAppointment;
  final Branch? preferredBranch;
  final Barber? preferredBarber;
  final Service? favoriteService;
  final double averageRatingGiven;

  bool get hasUpcoming => nextAppointment != null;

  factory ClientDashboard.fromJson(Map<String, dynamic> json) {
    final next = Json.asMap(json['next_appointment']);
    final branch = Json.asMap(json['preferred_branch']);
    final barber = Json.asMap(json['preferred_barber']);
    final service = Json.asMap(json['favorite_service']);

    return ClientDashboard(
      totalVisits: Json.asInt(json['total_visits']),
      totalSpent: Json.asDouble(json['total_spent']),
      averageTicket: Json.asDouble(json['average_ticket']),
      loyaltyPoints: Json.asInt(json['loyalty_points']),
      upcomingCount: Json.asInt(json['upcoming_count']),
      pendingReviews: Json.asInt(json['pending_reviews']),
      reviewsGiven: Json.asInt(json['reviews_given']),
      lastVisitAt: Json.asDate(json['last_visit_at']),
      nextAppointment: next.isEmpty ? null : Appointment.fromJson(next),
      preferredBranch: branch.isEmpty ? null : Branch.fromJson(branch),
      preferredBarber: barber.isEmpty ? null : Barber.fromJson(barber),
      favoriteService: service.isEmpty ? null : Service.fromJson(service),
      averageRatingGiven: Json.asDouble(json['average_rating_given']),
    );
  }
}
