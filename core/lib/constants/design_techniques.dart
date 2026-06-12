/// Canonical embroidery technique vocabulary.
///
/// Stored on design docs as `techniques: List<String>` using these exact
/// values (kept as strings, not an enum, so the vocabulary can grow without
/// a data migration). Display labels are localized app-side.
class DesignTechniques {
  DesignTechniques._();

  static const String aari = 'Aari';
  static const String zardosi = 'Zardosi';
  static const String mirrorWork = 'Mirror Work';
  static const String beadWork = 'Bead Work';
  static const String sequinWork = 'Sequin Work';
  static const String threadEmbroidery = 'Thread Embroidery';
  static const String cutwork = 'Cutwork';
  static const String applique = 'Applique';
  static const String kantha = 'Kantha';
  static const String chikankari = 'Chikankari';
  static const String phulkari = 'Phulkari';
  static const String stoneWork = 'Stone Work';
  static const String patchWork = 'Patch Work';
  static const String machineEmbroidery = 'Machine Embroidery';

  static const List<String> all = [
    aari,
    zardosi,
    mirrorWork,
    beadWork,
    sequinWork,
    threadEmbroidery,
    cutwork,
    applique,
    kantha,
    chikankari,
    phulkari,
    stoneWork,
    patchWork,
    machineEmbroidery,
  ];
}
