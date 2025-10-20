%% Linear vs Quadratic fit LLR Comparison
neuron_filter = logical(ones(size(stats,1),1)); %stats.evoked_spikes<0.05;

figure; hold on;
%% pEvoked_v_pBase_LLR
subplot(1,4,1); hold on;
histogram(stats.pEvoked_v_pBase_LLR(logical(session_numbers_unique)),'BinWidth',1)
xline(3.841);
title({'pEvoked vs pBase LLR', ['NAN = ' num2str(sum(isnan(stats.pEvoked_v_pBase_LLR(logical(session_numbers_unique)))))]});

%% sEvoked_v_sBase_LLR
subplot(1,4,2); hold on;
histogram(stats.sEvoked_v_sBase_LLR(neuron_filter),'BinWidth',1)
xline(3.841);
title({'sEvoked vs sBase LLR', ['NAN = ' num2str(sum(isnan(stats.sEvoked_v_sBase_LLR(neuron_filter))))]});

%% pEvoked_v_sBase_LLR
subplot(1,4,3); hold on;
histogram(stats.pEvoked_v_sBase_LLR(neuron_filter),'BinWidth',1)
xline(3.841);
title({'pEvoked vs sBase LLR', ['NAN = ' num2str(sum(isnan(stats.pEvoked_v_sBase_LLR(neuron_filter))))]});

%% sEvoked_v_pBase_LLR
subplot(1,4,4); hold on;
histogram(stats.sEvoked_v_pBase_LLR(neuron_filter),'BinWidth',1)
xline(3.841);
title({'sEvoked vs pBase LLR', ['NAN = ' num2str(sum(isnan(stats.sEvoked_v_pBase_LLR(neuron_filter))))]});
