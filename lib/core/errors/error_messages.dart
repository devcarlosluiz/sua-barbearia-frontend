/// Tradução dos códigos de erro da API para mensagens amigáveis.
///
/// O backend devolve um código estável (ex.: `BARBER_NOT_AVAILABLE`); aqui ele
/// vira um texto que o usuário entende. Nunca exibimos stack trace.
class ErrorMessages {
  const ErrorMessages._();

  static const Map<String, String> _messages = {
    // --- Autenticação ---
    'UNAUTHENTICATED': 'Sua sessão expirou. Entre novamente.',
    'PERMISSION_DENIED': 'Você não tem permissão para esta ação.',
    'ACCOUNT_INACTIVE': 'Sua conta está inativa. Fale com a barbearia.',
    'INVALID_REFRESH_TOKEN': 'Sessão inválida. Faça login novamente.',
    'INVALID_RESET_TOKEN':
        'O link de redefinição expirou. Solicite um novo e-mail.',

    // --- Agendamento ---
    'SLOT_NOT_AVAILABLE':
        'Este horário não está mais disponível. Escolha outro.',
    'SLOT_ALREADY_TAKEN':
        'Alguém acabou de reservar este horário. Escolha outro.',
    'BARBER_NOT_AVAILABLE': 'O barbeiro não está disponível neste horário.',
    'BARBER_NOT_IN_BRANCH': 'Este barbeiro não atende na filial escolhida.',
    'BARBER_DOES_NOT_PERFORM_SERVICE':
        'Este barbeiro não realiza o serviço selecionado.',
    'BARBER_INACTIVE': 'Este barbeiro não está disponível no momento.',
    'BRANCH_INACTIVE': 'Esta filial não está disponível no momento.',
    'SERVICE_INACTIVE': 'Este serviço não está disponível no momento.',
    'DATE_IN_PAST': 'Não é possível agendar em datas passadas.',
    'DATE_TOO_FAR': 'Esta data ainda não está aberta para agendamento.',
    'CANCELLATION_DEADLINE_PASSED':
        'O prazo para cancelar pelo aplicativo já passou. Ligue para a barbearia.',
    'APPOINTMENT_ALREADY_FINISHED': 'Este agendamento já foi finalizado.',
    'APPOINTMENT_IN_PROGRESS':
        'O atendimento já começou e não pode ser remarcado.',
    'APPOINTMENT_NOT_STARTED': 'Inicie o atendimento antes de finalizá-lo.',
    'INVALID_STATUS_TRANSITION': 'Esta mudança de status não é permitida.',
    'APPOINTMENT_COMPLETED_CANNOT_DELETE':
        'Um atendimento concluído não pode ser excluído: ele já gerou '
            'pagamento, comissão e pontos.',
    'APPOINTMENT_NOT_DELETABLE_BY_CLIENT':
        'Este agendamento não pode mais ser excluído pelo aplicativo. '
            'Fale com a barbearia.',
    'APPOINTMENT_HAS_PAYMENT':
        'Há um pagamento vinculado a este agendamento. Estorne antes de excluir.',
    'CLIENT_REQUIRED': 'Selecione o cliente do agendamento.',

    // --- Financeiro e pagamentos ---
    'DISCOUNT_GREATER_THAN_AMOUNT':
        'O desconto não pode ser maior que o valor do atendimento.',
    'DISCOUNT_GREATER_THAN_TOTAL':
        'O desconto não pode ser maior que o total da venda.',
    'PAYMENT_NOT_REFUNDABLE':
        'Somente pagamentos quitados podem ser estornados.',
    'NO_PENDING_COMMISSIONS': 'Nenhuma comissão pendente foi encontrada.',

    // --- Estoque ---
    'INSUFFICIENT_STOCK': 'Estoque insuficiente para concluir a venda.',
    'INVALID_QUANTITY': 'Informe uma quantidade válida.',
    'SALE_WITHOUT_ITEMS': 'Adicione ao menos um produto à venda.',
    'SALE_NOT_OPEN': 'Esta venda já foi finalizada ou cancelada.',
    'SALE_ALREADY_CANCELLED': 'Esta venda já está cancelada.',
    'PRODUCT_NOT_FOUND': 'Produto não encontrado ou inativo.',

    // --- Fidelidade ---
    'INSUFFICIENT_POINTS': 'Você ainda não tem pontos suficientes.',
    'REWARD_INACTIVE': 'Esta recompensa não está mais disponível.',
    'REWARD_NOT_FOUND': 'Recompensa não encontrada.',
    'LOYALTY_ACCOUNT_NOT_FOUND': 'Conta de fidelidade não encontrada.',

    // --- Planos mensais e assinaturas ---
    'PLAN_UNAVAILABLE': 'Este plano não está mais disponível.',
    'PLAN_HAS_SUBSCRIBERS':
        'Este plano tem assinantes ativos. Desative-o em vez de excluir.',
    'PLAN_BRANCH_NOT_ALLOWED': 'Este plano não é válido na filial escolhida.',
    'SUBSCRIPTION_ALREADY_EXISTS':
        'Você já tem uma assinatura em andamento. Cancele a atual para assinar outra.',
    'SUBSCRIPTION_NOT_ACTIVE': 'Esta assinatura já está encerrada.',
    'SUBSCRIPTION_IS_RECURRING':
        'Esta assinatura é cobrada automaticamente no cartão.',
    'INVALID_BILLING_TYPE': 'Forma de cobrança inválida.',
    'INVOICE_ALREADY_PAID': 'Esta fatura já está paga.',
    'INVOICE_NOT_PAYABLE': 'Esta fatura não pode ser confirmada.',
    'CLIENT_PROFILE_REQUIRED': 'Apenas clientes podem assinar um plano.',
    'GATEWAY_NOT_CONFIGURED':
        'O pagamento online não está configurado. Fale com a barbearia.',
    'GATEWAY_ERROR':
        'Não foi possível falar com o meio de pagamento. Tente novamente.',

    // --- Avaliações ---
    'REVIEW_ALREADY_EXISTS': 'Você já avaliou este atendimento.',
    'APPOINTMENT_NOT_COMPLETED':
        'Só é possível avaliar atendimentos concluídos.',

    // --- Perfis ---
    'CLIENT_PROFILE_NOT_FOUND': 'Perfil de cliente não encontrado.',
    'BARBER_PROFILE_NOT_FOUND': 'Perfil de barbeiro não encontrado.',
    'CLIENT_NOT_FOUND': 'Cliente não encontrado.',
    'BRANCH_NOT_FOUND': 'Filial não encontrada.',
    'BARBER_NOT_FOUND': 'Barbeiro não encontrado.',
    'SERVICE_NOT_FOUND': 'Serviço não encontrado.',
    'NOT_FOUND': 'Registro não encontrado.',

    // --- Genéricos ---
    'VALIDATION_ERROR': 'Verifique os dados informados e tente novamente.',
    'INVALID_DATE': 'Data inválida.',
    'INVALID_PERIOD': 'Período inválido.',
    'THROTTLED': 'Muitas tentativas. Aguarde um instante e tente de novo.',
    'METHOD_NOT_ALLOWED': 'Operação não permitida.',
    'CONFLICT': 'Não foi possível concluir: o registro foi alterado.',
    'INTERNAL_ERROR':
        'Tivemos um problema por aqui. Tente novamente em instantes.',
    'NETWORK_ERROR':
        'Sem conexão com o servidor. Verifique sua internet e tente de novo.',
    'TIMEOUT': 'O servidor demorou para responder. Tente novamente.',
    'CANCELLED': 'A operação foi cancelada.',
  };

  /// Mensagem amigável para o [code]. Usa [fallback] quando o código é
  /// desconhecido — assim mensagens novas do backend ainda chegam ao usuário.
  static String forCode(String code, {String? fallback}) {
    return _messages[code] ??
        fallback ??
        'Não foi possível concluir a operação. Tente novamente.';
  }
}
