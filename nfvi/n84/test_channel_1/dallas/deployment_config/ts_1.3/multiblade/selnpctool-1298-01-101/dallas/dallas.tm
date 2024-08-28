%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%%%%%%%%%%%%%  TRAFFIC MODEL 5G   %%%%%%%%%%%%%%%%%%%%%%%%%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Traffic Model description for 5G subscribers
%%
{tm, [
	{name, nr_multitm},
	{tm_control, [
		{enable_traffic_during_startup, false},
		{initial_activations_per_sec, 50},
		{sds_to_total_subs_ratio, 0.8},
		{sim_delays, true},
		{tm_latency, [
			{max_tm_latency, 6000},
			{min_tm_latency, 5000}
		]}, 
		{max_random_delay, 0}, 
		{always_on, true},
		{initial_pdu_session_ratio, 0.992}
	]}, 
	{access_control, [
		{nr, [
			{registration_deregistration,[
				{sau_based_rate, 1.2},
				{initial_registration_mobile_identity_type_weight, [
					{suci, 30},
					{guti, 70}
				]},
				{deregistration_cause_weight, [
					{power_off, 5},
					{normal, 95}
				]}
			]},
			{an_release, [
				{active_to_idle_timeout,27} 
			]}  
		]}  
	]}, 
	{session_control, [
		{nr, [
			{session_creation, [
				{pdu_session, [
					{sau_based_rate, 0.01}
				]}  
			]},
			{session_modification, [
				{smf_initial_modification, [
					{sau_based_rate, 0}
				]}
			]},
			{session_deletion, [
				{pdu_session, [
					{sau_based_rate, 0.01}
				]}  
			]}  
		]}  
	]}, 
	{mobility_control, [
		{nr, [
			{n2_handover, [
				{per_type_rate, [
					{amf_change, false},
					{upf_change, false},
					{smf_change, false},
					{sau_based_rate, 0}
				]} 
			]},
			{xn_handover, [
				{per_type_rate, [
					{amf_change, false},
					{upf_change, false},
					{smf_change, false},
					{sau_based_rate, 0}
				]}
			]},
			{mobility_registration, [
				{intra_amf, [
					{sau_based_rate, 1.6}
				]},
				{inter_amf, [
					{sau_based_rate, 0}
				]}
			]}
		]}
	]},
	{payload_control, [
		{nr, [
			{sau_based_rate, 20}
		]}
	]}
]}.

