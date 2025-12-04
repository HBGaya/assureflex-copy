// lib/data/models/claim_form_request.dart
class PlanParticipant {
  final String firstName;
  final String lastName;
  final String relationshipToEmployee;
  final String fee;

  PlanParticipant({
    required this.firstName,
    required this.lastName,
    required this.relationshipToEmployee,
    required this.fee,
  });
}

class ServiceProvider {
  final String name;
  final String address;
  final String firstName;
  final String lastName;
  final String relationshipToEmployee;
  final String fee; // can be empty

  ServiceProvider({
    required this.name,
    required this.address,
    required this.firstName,
    required this.lastName,
    required this.relationshipToEmployee,
    required this.fee,
  });
}

class ClaimFormRequest {
  final String employerName;
  final String firstName;
  final String middleName;
  final String lastName;
  final String employeeDateOfSignature; // yyyy-MM-dd
  final List<PlanParticipant> planParticipants;
  final String planParticipantTotalFee;
  final List<ServiceProvider> serviceProviders;
  final String serviceProviderTotalFee;
  final String formTotalFee;

  ClaimFormRequest({
    required this.employerName,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.employeeDateOfSignature,
    required this.planParticipants,
    required this.planParticipantTotalFee,
    required this.serviceProviders,
    required this.serviceProviderTotalFee,
    required this.formTotalFee,
  });

  /// Backend expects array-like keys:
  /// plan_participants[0][first_name], service_providers[0][name], etc.
  Map<String, dynamic> toFormMap() {
    final map = <String, dynamic>{
      'employer_name': employerName,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'employe_date_of_signature': employeeDateOfSignature,
      'plan_participant_total_fee': planParticipantTotalFee,
      'service_provider_total_fee': serviceProviderTotalFee,
      'form_total_fee': formTotalFee,
    };

    for (var i = 0; i < planParticipants.length; i++) {
      final p = planParticipants[i];
      map['plan_participants[$i][first_name]'] = p.firstName;
      map['plan_participants[$i][last_name]'] = p.lastName;
      map['plan_participants[$i][relationshop_to_employee]'] = p.relationshipToEmployee;
      map['plan_participants[$i][fee]'] = p.fee;
    }

    for (var i = 0; i < serviceProviders.length; i++) {
      final s = serviceProviders[i];
      map['service_providers[$i][name]'] = s.name;
      map['service_providers[$i][address]'] = s.address;
      map['service_providers[$i][first_name]'] = s.firstName;
      map['service_providers[$i][last_name]'] = s.lastName;
      map['service_providers[$i][relationshop_to_employee]'] = s.relationshipToEmployee;
      map['service_providers[$i][fee]'] = s.fee;
    }

    return map;
  }
}
