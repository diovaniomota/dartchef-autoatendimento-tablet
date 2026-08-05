import 'package:flutter/material.dart';

/// Idiomas oferecidos ao cliente no salao.
enum AppLanguage { pt, en, es }

/// Idioma atual do app.
///
/// Um ValueNotifier global em vez de gerenciador de estado: o app e pequeno,
/// ja usa setState, e o unico consumidor real e a arvore inteira (qualquer
/// troca redesenha tudo). A raiz escuta este notifier, entao nao existe
/// prop drilling de idioma por dezenas de widgets.
final ValueNotifier<AppLanguage> appLanguage = ValueNotifier(AppLanguage.pt);

/// Volta para portugues.
///
/// O tablet e compartilhado: um turista escolhe ingles, vai embora, e o
/// proximo cliente encontraria a tela em outro idioma. Chamado ao finalizar
/// um pedido e quando o tablet fica ocioso.
void resetLanguage() {
  if (appLanguage.value != AppLanguage.pt) {
    appLanguage.value = AppLanguage.pt;
  }
}

/// Traducao da chave no idioma atual, com portugues como retaguarda.
String t(String key) {
  final table = _translations[appLanguage.value] ?? const {};
  return table[key] ?? _translations[AppLanguage.pt]![key] ?? key;
}

/// Traducao com substituicao de marcadores: t2('table', {'code': '01'}).
String t2(String key, Map<String, String> params) {
  var text = t(key);
  params.forEach((name, value) {
    text = text.replaceAll('{$name}', value);
  });
  return text;
}

/// Idioma para formatacao de moeda. O preco continua em real: o restaurante
/// cobra em real independente do idioma da tela.
String get currencyLocale => 'pt_BR';

const Map<AppLanguage, Map<String, String>> _translations = {
  // ────────────────────────── PORTUGUES ──────────────────────────
  AppLanguage.pt: {
    'search.hint': 'O que você deseja comer hoje?',
    'topbar.table': 'MESA {code}',
    'topbar.waiter': 'Garçom',
    'topbar.myBill': 'Minha conta',
    'topbar.requestBill': 'Pedir a conta',
    'topbar.myOrder': 'MEU PEDIDO',
    'topbar.myOrderCount': 'MEU PEDIDO ({count})',

    'cart.summary': 'RESUMO DO PEDIDO',
    'cart.chefSuggestions': 'SUGESTÕES DO CHEF',
    'cart.subtotal': 'Subtotal',
    'cart.serviceFee': 'Taxa de Serviço (10%)',
    'cart.total': 'TOTAL',
    'cart.confirm': 'CONFIRMAR PEDIDO',
    'cart.sending': 'ENVIANDO...',
    'cart.remove': 'Remover',
    'cart.addNote': 'Adicionar observação',
    'cart.editNote': 'Alterar observação',

    'product.add': 'Adicionar',
    'product.featured': 'Destaque',
    'product.unitPrice': 'Preço unitário',
    'product.addUpper': 'ADICIONAR',
    'product.from': 'A partir de',

    'sidebar.featured': 'DESTAQUES',
    'sidebar.all': 'Todos',

    'highlights.title': 'Destaques da Semana',
    'highlights.subtitle': 'As melhores escolhas preparadas por nossos chefs',
    'highlights.mostOrdered': 'O MAIS PEDIDO',
    'highlights.seeAll': 'Ver tudo >',
    'highlights.empty': 'Nenhum produto disponível.',

    'confirm.title': 'Confirme seu Pedido',
    'confirm.subtitle': 'Revise os itens antes de enviar para a cozinha',
    'confirm.action': 'CONFIRMAR E ENVIAR',
    'confirm.items': 'Itens do Pedido ({count})',
    'confirm.destination': 'O pedido será enviado para a cozinha vinculado à Mesa {code}.',

    'notes.title': 'Observação — {product}',
    'notes.help': 'Escreva o que precisar. A cozinha recebe junto com o pedido.',
    'notes.hint': 'Ex.: sem salada, bebida com gelo',
    'notes.save': 'Salvar',
    'notes.cancel': 'Cancelar',
    'notes.clear': 'Remover observação',
    'notes.noSalad': 'Sem salada',
    'notes.noOnion': 'Sem cebola',
    'notes.noTomato': 'Sem tomate',
    'notes.noMayo': 'Sem maionese',
    'notes.withIce': 'Com gelo',
    'notes.noIce': 'Sem gelo',
    'notes.wellDone': 'Bem passado',
    'notes.lessSalt': 'Pouco sal',
    'notes.toShare': 'Para dividir',

    'call.waiterTitle': 'Chamar Garçom?',
    'call.waiterBody': 'Enviaremos uma notificação para o garçom atender a Mesa {code}.',
    'call.waiterConfirm': 'Chamar Garçom',
    'call.waiterSuccess': 'Garçom foi chamado! Aguarde um momento.',
    'call.billTitle': 'Pedir a conta?',
    'call.billBody': 'Vamos avisar o atendente que a Mesa {code} quer fechar a conta.',
    'call.billConfirm': 'Pedir a conta',
    'call.billSuccess': 'Pedido enviado! O atendente já vai levar a conta.',
    'call.cancel': 'Cancelar',

    'order.sent': 'Pedido #{id} enviado para a Mesa {code}!',
    'order.addFirst': 'Adicione itens antes de enviar.',
    'order.added': '{product} adicionado!',
    'options.optional': 'opcional',
    'welcome.chooseLanguage': 'ESCOLHA SEU IDIOMA',
    'welcome.start': 'TOQUE PARA COMEÇAR',
    'idle.title': 'Ainda está aí?',
    'idle.body': 'Sem resposta, o tablet volta para a tela inicial em {seconds}s.',
    'idle.stay': 'Continuar pedindo',
    'lang.label': 'Idioma',
  },

  // ────────────────────────── INGLES ──────────────────────────
  AppLanguage.en: {
    'search.hint': 'What would you like to eat today?',
    'topbar.table': 'TABLE {code}',
    'topbar.waiter': 'Waiter',
    'topbar.myBill': 'My bill',
    'topbar.requestBill': 'Request bill',
    'topbar.myOrder': 'MY ORDER',
    'topbar.myOrderCount': 'MY ORDER ({count})',

    'cart.summary': 'ORDER SUMMARY',
    'cart.chefSuggestions': "CHEF'S SUGGESTIONS",
    'cart.subtotal': 'Subtotal',
    'cart.serviceFee': 'Service charge (10%)',
    'cart.total': 'TOTAL',
    'cart.confirm': 'CONFIRM ORDER',
    'cart.sending': 'SENDING...',
    'cart.remove': 'Remove',
    'cart.addNote': 'Add a note',
    'cart.editNote': 'Edit note',

    'product.add': 'Add',
    'product.featured': 'Featured',
    'product.unitPrice': 'Unit price',
    'product.addUpper': 'ADD',
    'product.from': 'From',

    'sidebar.featured': 'FEATURED',
    'sidebar.all': 'All',

    'highlights.title': 'Weekly Highlights',
    'highlights.subtitle': 'The best picks prepared by our chefs',
    'highlights.mostOrdered': 'MOST ORDERED',
    'highlights.seeAll': 'See all >',
    'highlights.empty': 'No products available.',

    'confirm.title': 'Confirm your Order',
    'confirm.subtitle': 'Review the items before sending to the kitchen',
    'confirm.action': 'CONFIRM AND SEND',
    'confirm.items': 'Order Items ({count})',
    'confirm.destination': 'The order will be sent to the kitchen for Table {code}.',

    'notes.title': 'Note — {product}',
    'notes.help': 'Type what you need. The kitchen gets it with your order.',
    'notes.hint': 'E.g. no salad, drink with ice',
    'notes.save': 'Save',
    'notes.cancel': 'Cancel',
    'notes.clear': 'Remove note',
    'notes.noSalad': 'No salad',
    'notes.noOnion': 'No onion',
    'notes.noTomato': 'No tomato',
    'notes.noMayo': 'No mayo',
    'notes.withIce': 'With ice',
    'notes.noIce': 'No ice',
    'notes.wellDone': 'Well done',
    'notes.lessSalt': 'Less salt',
    'notes.toShare': 'To share',

    'call.waiterTitle': 'Call the waiter?',
    'call.waiterBody': 'We will notify the waiter to come to Table {code}.',
    'call.waiterConfirm': 'Call waiter',
    'call.waiterSuccess': 'The waiter has been called! Please wait a moment.',
    'call.billTitle': 'Request the bill?',
    'call.billBody': 'We will let the staff know that Table {code} wants the bill.',
    'call.billConfirm': 'Request bill',
    'call.billSuccess': 'Request sent! The staff will bring your bill.',
    'call.cancel': 'Cancel',

    'order.sent': 'Order #{id} sent for Table {code}!',
    'order.addFirst': 'Add items before sending.',
    'order.added': '{product} added!',
    'options.optional': 'optional',
    'welcome.chooseLanguage': 'CHOOSE YOUR LANGUAGE',
    'welcome.start': 'TOUCH TO START',
    'idle.title': 'Still there?',
    'idle.body': 'Without a reply, the tablet returns to the start screen in {seconds}s.',
    'idle.stay': 'Keep ordering',
    'lang.label': 'Language',
  },

  // ────────────────────────── ESPANHOL ──────────────────────────
  AppLanguage.es: {
    'search.hint': '¿Qué desea comer hoy?',
    'topbar.table': 'MESA {code}',
    'topbar.waiter': 'Camarero',
    'topbar.myBill': 'Mi cuenta',
    'topbar.requestBill': 'Pedir la cuenta',
    'topbar.myOrder': 'MI PEDIDO',
    'topbar.myOrderCount': 'MI PEDIDO ({count})',

    'cart.summary': 'RESUMEN DEL PEDIDO',
    'cart.chefSuggestions': 'SUGERENCIAS DEL CHEF',
    'cart.subtotal': 'Subtotal',
    'cart.serviceFee': 'Cargo por servicio (10%)',
    'cart.total': 'TOTAL',
    'cart.confirm': 'CONFIRMAR PEDIDO',
    'cart.sending': 'ENVIANDO...',
    'cart.remove': 'Quitar',
    'cart.addNote': 'Añadir nota',
    'cart.editNote': 'Editar nota',

    'product.add': 'Añadir',
    'product.featured': 'Destacado',
    'product.unitPrice': 'Precio unitario',
    'product.addUpper': 'AÑADIR',
    'product.from': 'Desde',

    'sidebar.featured': 'DESTACADOS',
    'sidebar.all': 'Todos',

    'highlights.title': 'Destacados de la Semana',
    'highlights.subtitle': 'Las mejores opciones preparadas por nuestros chefs',
    'highlights.mostOrdered': 'EL MÁS PEDIDO',
    'highlights.seeAll': 'Ver todo >',
    'highlights.empty': 'No hay productos disponibles.',

    'confirm.title': 'Confirme su Pedido',
    'confirm.subtitle': 'Revise los artículos antes de enviarlos a la cocina',
    'confirm.action': 'CONFIRMAR Y ENVIAR',
    'confirm.items': 'Artículos del Pedido ({count})',
    'confirm.destination': 'El pedido se enviará a la cocina vinculado a la Mesa {code}.',

    'notes.title': 'Nota — {product}',
    'notes.help': 'Escriba lo que necesite. La cocina lo recibe con su pedido.',
    'notes.hint': 'Ej.: sin ensalada, bebida con hielo',
    'notes.save': 'Guardar',
    'notes.cancel': 'Cancelar',
    'notes.clear': 'Quitar nota',
    'notes.noSalad': 'Sin ensalada',
    'notes.noOnion': 'Sin cebolla',
    'notes.noTomato': 'Sin tomate',
    'notes.noMayo': 'Sin mayonesa',
    'notes.withIce': 'Con hielo',
    'notes.noIce': 'Sin hielo',
    'notes.wellDone': 'Bien hecho',
    'notes.lessSalt': 'Poca sal',
    'notes.toShare': 'Para compartir',

    'call.waiterTitle': '¿Llamar al camarero?',
    'call.waiterBody': 'Avisaremos al camarero para que atienda la Mesa {code}.',
    'call.waiterConfirm': 'Llamar al camarero',
    'call.waiterSuccess': '¡Camarero llamado! Espere un momento.',
    'call.billTitle': '¿Pedir la cuenta?',
    'call.billBody': 'Avisaremos al personal que la Mesa {code} quiere la cuenta.',
    'call.billConfirm': 'Pedir la cuenta',
    'call.billSuccess': '¡Solicitud enviada! El personal le llevará la cuenta.',
    'call.cancel': 'Cancelar',

    'order.sent': '¡Pedido #{id} enviado a la Mesa {code}!',
    'order.addFirst': 'Añada artículos antes de enviar.',
    'order.added': '¡{product} añadido!',
    'options.optional': 'opcional',
    'welcome.chooseLanguage': 'ELIJA SU IDIOMA',
    'welcome.start': 'TOQUE PARA EMPEZAR',
    'idle.title': '¿Sigue ahí?',
    'idle.body': 'Sin respuesta, el tablet vuelve a la pantalla inicial en {seconds}s.',
    'idle.stay': 'Seguir pidiendo',
    'lang.label': 'Idioma',
  },
};
