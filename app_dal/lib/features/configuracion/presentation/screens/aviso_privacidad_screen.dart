import 'package:flutter/material.dart';

class AvisoPrivacidadScreen extends StatelessWidget {
  const AvisoPrivacidadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Aviso de Privacidad')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aviso de Privacidad',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SelectableText.rich(
                        TextSpan(
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                            color: theme.colorScheme.onSurface.withOpacity(0.9),
                          ),
                          children: const [
                            TextSpan(
                              text: '(1) ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: 'Identidad y domicilio de la responsable: '),
                            TextSpan(
                              text: 'DAL DEALER, S.A. de C.V.',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: ', con domicilio en '),
                            TextSpan(
                              text:
                                  'Carretera Estatal Km. 1+933.7 # 431 Col. El Colorado (EuroPark II) Nave 5B El Marqués, Querétaro. 76246 México',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: '; '),
                            TextSpan(
                              text: '(2) ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: 'Finalidades del tratamiento: a) para poder identificarle; b) para ponernos en contacto con usted para tratar cualquier tema relacionado con la contratación de servicios integrales especializados y comercialización de productos químicos, venta y/o renta de equipo; c) para poder interactuar con usted en diferentes medios electrónicos (públicos o privados) en los que usted voluntariamente participe o se ponga en contacto con nosotros; d) para compartir su nombre y/o imagen (fotografía o video) en material promocional de la empresa; e) enviarle todas las noticias, vídeos, boletines informativos, ofertas, promociones comerciales, lanzamientos de los nuevos productos y/o servicios de la empresa; f) su email y nombre serán tratados de manera confidencial y no serán cedidos a terceros; g) así mismo, le informamos que sus datos personales y/o financieros podrán ser transferidos y tratados dentro y fuera del país, a personas distintas a '),
                            TextSpan(
                              text: 'DAL DEALER, S.A. de C.V.',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: ' para las finalidades establecidas en el presente aviso de privacidad. En ese sentido su información podrá́ ser compartida con: (i) Contratistas o proveedores de servicio que complementen o coadyuven con la relación jurídica con la que tengamos con usted, socios comerciales y asesores de '),
                            TextSpan(
                              text: 'DAL DEALER, S.A. de C.V.',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: ' (ii) empresas nacionales y extranjeras que sean colaboradores de la responsable; (iii) autoridades en México o en el extranjero; (iv) cualquier otra persona autorizada por la ley o el reglamento aplicable. '),
                            TextSpan(
                              text: '(3) ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: 'Al momento de solicitar una cotización de un servicio integral especializado o la compra de algún producto o alquiler de equipo a '),
                            TextSpan(
                              text: 'DAL DEALER, S.A. de C.V.',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: ', ésta pone a su disposición el aviso de privacidad integral en el que le informamos de manera más amplia, el tratamiento que se dará a sus datos personales. '),
                            TextSpan(
                              text: '(4) ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: 'Usted tiene derecho de acceder, rectificar y cancelar sus datos personales, así como de oponerse al tratamiento de estos o revocar el consentimiento que para tal fin haya otorgado, lo que podrá hacer a través de los procedimientos que hemos implementado. Para ejercer ese derecho envíe su solicitud mediante un comunicado al correo electrónico a contacto@ddg.com.mx.   '),
                            TextSpan(
                              text: '(5) ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: 'Si Usted ya no desea seguir recibiendo este tipo de correos, simplemente haga “click” en “cancelar suscripción, leyenda que aparece al final de todos los comunicados que reciba de nuestra parte. '),
                            TextSpan(
                              text: '(6) ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: 'Todo lo anterior, con sustento en normatividad y leyes mexicanas.'),
                          ],
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
