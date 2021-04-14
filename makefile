RSCRIPT = Rscript
PLOT_SETTINGS = scripts/common/plot-settings.R
TEX_FILES = $(wildcard tex-input/*.tex) \
	$(wildcard tex-input/*/*.tex) \
	$(wildcard tex-input/*/*/*.tex)
MCMC_UTIL = scripts/common/mcmc-util.R
BIBLIOGRAPHY = bibliography/multi-phi-bib.bib

# useful compound make components
PLOTS = plots
RDS = rds
SCRIPTS = scripts

# ALL figures
ALL_PLOTS =

# if you wildcard the all-target, then nothing will happen if the target doesn't
# exist (no target). hard code the target.
# CHANGE THIS:
BASENAME = multiple-phi
WRITEUP = $(BASENAME).pdf

all : $(WRITEUP)

clean :
	trash \
		$(BASENAME).aux \
		$(BASENAME).out \
		$(BASENAME).pdf \
		$(BASENAME).tex \
		$(BASENAME).log \
		Rplots.pdf

################################################################################
## Pooling visualisation tests
POOLING_TESTS = pooling-tests
POOLING_SCRIPTS = scripts/$(POOLING_TESTS)
POOLING_OUTPUTS = rds/$(POOLING_TESTS)
POOLING_PLOTS = plots/pooling-tests

POOLED_PLOT_2D = $(POOLING_PLOTS)/version-two.pdf
$(POOLING_SCRIPTS)/sub-plot-maker.R : $(POOLING_SCRIPTS)/density-functions.R

$(POOLED_PLOT_2D) : $(POOLING_SCRIPTS)/plot-pooled-priors.R  $(PLOT_SETTINGS) $(POOLING_SCRIPTS)/sub-plot-maker.R
	$(RSCRIPT) $<

ALL_PLOTS += $(POOLED_PLOT_2D)

################################################################################
## Owls example
OWLS_BASENAME = owls-example
OWLS_DATA = $(wildcard rds/owls-example/*-data.rds)
OWLS_SCRIPTS = $(SCRIPTS)/$(OWLS_BASENAME)
OWLS_RDS = $(RDS)/$(OWLS_BASENAME)
OWLS_PLOTS = $(PLOTS)/$(OWLS_BASENAME)
OWLS_POSTERIOR_SAMPLES = $(wildcard rds/owls-example/*-samples.rds)

$(OWLS_DATA) : $(OWLS_SCRIPTS)/load-and-write-data.R
	$(RSCRIPT) $<

ORIG_IPM_SAMPLES = $(OWLS_RDS)/original-ipm-samples.rds
$(ORIG_IPM_SAMPLES) : $(OWLS_SCRIPTS)/fit-original-ipm.R $(OWLS_SCRIPTS)/models/original-ipm.bug $(OWLS_DATA)
	$(RSCRIPT) $<

FECUNDITY_SUBPOSTERIOR = $(OWLS_RDS)/fecundity-subposterior-samples.rds
$(FECUNDITY_SUBPOSTERIOR) : $(OWLS_SCRIPTS)/fit-fecundity.R $(OWLS_SCRIPTS)/models/fecundity-model.stan $(FECUNDITY_DATA)
	$(RSCRIPT) $<

CAPTURE_RECAPTURE_SUBPOSTERIOR = $(OWLS_RDS)/capture-recapture-subposterior-samples.rds
$(CAPTURE_RECAPTURE_SUBPOSTERIOR) : $(OWLS_SCRIPTS)/fit-capture-recapture.R $(OWLS_SCRIPTS)/models/capture-recapture.bug $(OWLS_DATA)
	$(RSCRIPT) $<

FECUNDITY_DIAGNOSTIC_PLOT = $(OWLS_PLOTS)/stage-one-diagnostics-fecundity.png
$(FECUNDITY_DIAGNOSTIC_PLOT) : $(OWLS_SCRIPTS)/diagnostics-stage-one-fecundity-plot.R $(PLOT_SETTINGS) $(FECUNDITY_SUBPOSTERIOR)
	$(RSCRIPT) $<

CAPTURE_RECAPTURE_DIAGNOSTIC_PLOT = $(OWLS_PLOTS)/stage-one-diagnostics-capture-recapture.png
$(CAPTURE_RECAPTURE_DIAGNOSTIC_PLOT) : $(OWLS_SCRIPTS)/diagnostics-stage-one-capture-recapture-plot.R $(PLOT_SETTINGS) $(CAPTURE_RECAPTURE_SUBPOSTERIOR)
	$(RSCRIPT) $<

ALL_PLOTS += $(FECUNDITY_DIAGNOSTIC_PLOT) $(CAPTURE_RECAPTURE_DIAGNOSTIC_PLOT)

STAGE_ONE_DIAGNOSTIC_TABLE = tex-input/owls-example/appendix-info/0010-stage-one-diagnostics.tex
$(STAGE_ONE_DIAGNOSTIC_TABLE) : $(OWLS_SCRIPTS)/diagnostics-stage-one-table.R $(FECUNDITY_SUBPOSTERIOR) $(CAPTURE_RECAPTURE_SUBPOSTERIOR)
	$(RSCRIPT) $<

COUNT_DATA_SUBPOSTERIOR = $(OWLS_RDS)/count-data-subposterior-samples.rds
$(COUNT_DATA_SUBPOSTERIOR) : $(OWLS_SCRIPTS)/fit-count-data.R $(OWLS_SCRIPTS)/models/count-data.bug $(OWLS_DATA)
	$(RSCRIPT) $<

NORMAL_APPROX_MELDED_POSTERIOR = $(OWLS_RDS)/melded-posterior-normal-approx-samples.rds
$(NORMAL_APPROX_MELDED_POSTERIOR) : $(OWLS_SCRIPTS)/fit-normal-approx.R $(CAPTURE_RECAPTURE_SUBPOSTERIOR) $(FECUNDITY_SUBPOSTERIOR) $(OWLS_DATA) $(OWLS_SCRIPTS)/models/count-data-normal-approx.bug
	$(RSCRIPT) $<

MELDED_POSTERIOR = $(OWLS_RDS)/melded-posterior-samples.rds
$(MELDED_POSTERIOR) : $(OWLS_SCRIPTS)/mcmc-main-stage-two.R $(OWLS_SCRIPTS)/mcmc-nimble-functions.R $(FECUNDITY_SUBPOSTERIOR) $(CAPTURE_RECAPTURE_SUBPOSTERIOR) $(OWLS_DATA)
	$(RSCRIPT) $<

MELDED_POSTERIOR_PHI_LOG_POOLING = $(OWLS_RDS)/melded-phi-samples-log-pooling.rds
$(MELDED_POSTERIOR_PHI_LOG_POOLING) : $(OWLS_SCRIPTS)/fit-chained-other-pooled-priors.R $(MCMC_UTIL) $(MELDED_POSTERIOR)
	$(RSCRIPT) $<

MELDED_POSTERIOR_PHI_LIN_POOLING = $(OWLS_RDS)/melded-phi-samples-lin-pooling.rds
MELDED_POSTERIOR_INDICES_LOG_POOLING = $(OWLS_RDS)/melded-indices-log-pooling.rds
MELDED_POSTERIOR_INDICES_LIN_POOLING = $(OWLS_RDS)/melded-indices-lin-pooling.rds
$(MELDED_POSTERIOR_PHI_LIN_POOLING) : $(MELDED_POSTERIOR_PHI_LOG_POOLING)
$(MELDED_POSTERIOR_INDICES_LOG_POOLING) : $(MELDED_POSTERIOR_PHI_LOG_POOLING)
$(MELDED_POSTERIOR_INDICES_LIN_POOLING) : $(MELDED_POSTERIOR_PHI_LOG_POOLING)

SUBPOSTERIOR_PLOT = $(OWLS_PLOTS)/subposteriors.pdf
$(SUBPOSTERIOR_PLOT) : $(OWLS_SCRIPTS)/plot-subposteriors.R $(PLOT_SETTINGS) $(MCMC_UTIL) $(ORIG_IPM_SAMPLES) $(FECUNDITY_SUBPOSTERIOR) $(CAPTURE_RECAPTURE_SUBPOSTERIOR) $(COUNT_DATA_SUBPOSTERIOR) $(MELDED_POSTERIOR) $(NORMAL_APPROX_MELDED_POSTERIOR) $(MELDED_POSTERIOR_PHI_LOG_POOLING) $(MELDED_POSTERIOR_PHI_LIN_POOLING)
	$(RSCRIPT) $<

ALL_PLOTS += $(SUBPOSTERIOR_PLOT)

MELDED_DIAGNOSTIC_TABLE = tex-input/owls-example/appendix-info/0020-stage-two-diagnostics.tex
$(MELDED_DIAGNOSTIC_TABLE) : $(OWLS_SCRIPTS)/diagnostics-stage-two-table.R $(MELDED_POSTERIOR)
	$(RSCRIPT) $<

MELDED_DIAGNOSTIC_PLOT = $(OWLS_PLOTS)/stage-two-diagnostics.png
$(MELDED_DIAGNOSTIC_PLOT) : $(OWLS_SCRIPTS)/diagnostics-stage-two-plot.R $(MELDED_POSTERIOR) $(PLOT_SETTINGS)
	$(RSCRIPT) $<

MELDED_QQ_PLOT = $(OWLS_PLOTS)/orig-meld-qq-compare.pdf
$(MELDED_QQ_PLOT) : $(OWLS_SCRIPTS)/plot-qq-comparison.R $(MELDED_POSTERIOR) $(ORIG_IPM_SAMPLES) $(PLOT_SETTINGS)
	$(RSCRIPT) $<

ALL_PLOTS += $(MELDED_DIAGNOSTIC_PLOT) $(MELDED_QQ_PLOT)

################################################################################
## surv-example
SURV_BASENAME = surv-example
SURV_SCRIPTS = $(SCRIPTS)/$(SURV_BASENAME)
SURV_RDS = $(RDS)/$(SURV_BASENAME)
SURV_PLOTS = $(PLOTS)/$(SURV_BASENAME)
SURV_MODELS = $(SURV_SCRIPTS)/models
SURV_TEX = tex-input/$(SURV_BASENAME)

SURV_GLOBAL_SETTINGS = $(SURV_SCRIPTS)/GLOBALS.R

### Submodel 1
SURV_SIMULATION_SETTINGS = $(SURV_RDS)/simulation-settings-and-joint-data.rds
$(SURV_SIMULATION_SETTINGS) : $(SURV_SCRIPTS)/simulation-settings-and-joint-data.R $(SURV_GLOBAL_SETTINGS)
	$(RSCRIPT) $<

SURV_SUBMODEL_ONE_SIMULATED_DATA = $(SURV_RDS)/submodel-one-simulated-data.rds
$(SURV_SUBMODEL_ONE_SIMULATED_DATA) : $(SURV_SCRIPTS)/simulate-data-submodel-one.R $(SURV_SIMULATION_SETTINGS)
	$(RSCRIPT) $<

SURV_SUMODEL_ONE = $(SURV_MODELS)/submodel-one.stan

SURV_SUBMODEL_ONE_OUTPUT = $(SURV_RDS)/submodel-one-output.rds
$(SURV_SUBMODEL_ONE_OUTPUT) : $(SURV_SCRIPTS)/fit-submodel-one.R $(SURV_SUBMODEL_ONE_SIMULATED_DATA) $(SURV_SUMODEL_ONE)
	$(RSCRIPT) $<

SURV_ALL_SUBMODEL_ONE_INPUTS = $(SURV_SIMULATION_SETTINGS) $(SURV_SUBMODEL_ONE_SIMULATED_DATA) $(SURV_SUBMODEL_ONE_OUTPUT)

SURV_SUBMODEL_ONE_POSTERIOR_PLOT_DATA = $(SURV_RDS)/plot-submodel-1-data.rds
$(SURV_SUBMODEL_ONE_POSTERIOR_PLOT_DATA) : $(SURV_SCRIPTS)/prepare-submodel-one-plot-data.R $(MCMC_UTIL) $(SURV_ALL_SUBMODEL_ONE_INPUTS)
	$(RSCRIPT) $<

SURV_SUBMODEL_ONE_POSTERIOR_PLOT = $(SURV_PLOTS)/submodel-one-posterior.pdf
$(SURV_SUBMODEL_ONE_POSTERIOR_PLOT) : $(SURV_SCRIPTS)/plot-submodel-one.R $(PLOT_SETTINGS) $(SURV_SUBMODEL_ONE_POSTERIOR_PLOT_DATA) $(SURV_SIMULATION_SETTINGS)
	$(RSCRIPT) $<

ALL_PLOTS += $(SURV_SUBMODEL_ONE_POSTERIOR_PLOT)

SURV_SUBMODEL_ONE_DIAG_PLOT = $(SURV_PLOTS)/stage-one-submodel-one-diags.png
$(SURV_SUBMODEL_ONE_DIAG_PLOT) : $(SURV_SCRIPTS)/diagnose-submodel-one-plots.R $(PLOT_SETTINGS) $(MCMC_UTIL) $(SURV_SUBMODEL_ONE_OUTPUT)
	$(RSCRIPT) $<

ALL_PLOTS += $(SURV_SUBMODEL_ONE_DIAG_PLOT)

SURV_SUBMODEL_ONE_DIAG_TABLE = $(SURV_TEX)/0080-submodel-one-numeric-diags.tex
$(SURV_SUBMODEL_ONE_DIAG_TABLE) : $(SURV_SCRIPTS)/diagnose-submodel-one-tables.R $(MCMC_UTIL) $(SURV_SUBMODEL_ONE_OUTPUT)
	$(RSCRIPT) $<

TEX_FILES += $(SURV_SUBMODEL_ONE_DIAG_TABLE)

### Submodel 3

SURV_SUBMODEL_THREE_SIMULATED_DATA = $(SURV_RDS)/submodel-three-simulated-data.rds
$(SURV_SUBMODEL_THREE_SIMULATED_DATA) : $(SURV_SCRIPTS)/simulate-data-submodel-three.R $(SURV_SIMULATION_SETTINGS)
	$(RSCRIPT) $<

SURV_SUMODEL_THREE = $(SURV_MODELS)/submodel-three.stan
SURV_SUBMODEL_THREE_OUTPUT = $(SURV_RDS)/submodel-three-output.rds
$(SURV_SUBMODEL_THREE_OUTPUT) : $(SURV_SCRIPTS)/fit-submodel-three.R $(SURV_SUBMODEL_THREE_SIMULATED_DATA) $(SURV_SUMODEL_THREE)
	$(RSCRIPT) $<

SURV_ALL_SUBMODEL_THREE_INPUTS = $(SURV_SIMULATION_SETTINGS) $(SURV_SUBMODEL_THREE_SIMULATED_DATA) $(SURV_SUBMODEL_THREE_OUTPUT)

SURV_SUBMODEL_THREE_POSTERIOR_PLOT_DATA = $(SURV_RDS)/plot-submodel-3-data.rds
$(SURV_SUBMODEL_THREE_POSTERIOR_PLOT_DATA) : $(SURV_SCRIPTS)/prepare-submodel-three-plot-data.R $(MCMC_UTIL) $(SURV_ALL_SUBMODEL_THREE_INPUTS)
	$(RSCRIPT) $<

SURV_SUBMODEL_THREE_POSTERIOR_PLOT = $(SURV_PLOTS)/submodel-three-posterior.pdf
$(SURV_SUBMODEL_THREE_POSTERIOR_PLOT) : $(SURV_SCRIPTS)/plot-submodel-three.R $(PLOT_SETTINGS) $(SURV_SUBMODEL_THREE_POSTERIOR_PLOT_DATA)
	$(RSCRIPT) $<

ALL_PLOTS += $(SURV_SUBMODEL_THREE_POSTERIOR_PLOT)

SURV_SUBMODEL_THREE_DIAG_PLOT = $(SURV_PLOTS)/stage-one-submodel-three-diags.png
$(SURV_SUBMODEL_THREE_DIAG_PLOT) : $(SURV_SCRIPTS)/diagnose-submodel-three-plots.R $(PLOT_SETTINGS) $(MCMC_UTIL) $(SURV_SUBMODEL_THREE_OUTPUT)
	$(RSCRIPT) $<

ALL_PLOTS += $(SURV_SUBMODEL_THREE_DIAG_PLOT)

SURV_SUBMODEL_THREE_DIAG_TABLE = $(SURV_TEX)/0081-submodel-three-numeric-diags.tex
$(SURV_SUBMODEL_THREE_DIAG_TABLE) : $(SURV_SCRIPTS)/diagnose-submodel-three-tables.R $(MCMC_UTIL) $(SURV_SUBMODEL_THREE_OUTPUT)
	$(RSCRIPT) $<

TEX_FILES += $(SURV_SUBMODEL_THREE_DIAG_TABLE)

SURV_BOTH_LONGITUDINAL_PLOT = $(SURV_PLOTS)/both-longitudinal-submodels.pdf
$(SURV_BOTH_LONGITUDINAL_PLOT) : $(SURV_SCRIPTS)/plot-both-longitudinal-submodels.R $(PLOT_SETTINGS) $(SURV_SUBMODEL_ONE_POSTERIOR_PLOT_DATA) $(SURV_SUBMODEL_THREE_POSTERIOR_PLOT_DATA)
	$(RSCRIPT) $<

ALL_PLOTS += $(SURV_BOTH_LONGITUDINAL_PLOT)

### Process stage one output
SURV_EXAMPLE_STAGE_ONE_PHI_12 = $(SURV_RDS)/stage-one-phi-12-samples.rds
SURV_EXAMPLE_STAGE_ONE_PHI_12_POST_MEDIAN = $(SURV_RDS)/stage-one-phi-12-posterior-median.rds
SURV_EXAMPLE_STAGE_ONE_PHI_23 = $(SURV_RDS)/stage-one-phi-23-samples.rds
SURV_EXAMPLE_STAGE_ONE_PHI_23_POST_MEDIAN = $(SURV_RDS)/stage-one-phi-23-posterior-median.rds
SURV_EXAMPLE_POST_MEDIANS = $(SURV_EXAMPLE_STAGE_ONE_PHI_12_POST_MEDIAN) $(SURV_EXAMPLE_STAGE_ONE_PHI_23_POST_MEDIAN)

$(SURV_EXAMPLE_STAGE_ONE_PHI_12) : $(SURV_SCRIPTS)/process-submodel-one.R $(SURV_SUBMODEL_ONE_OUTPUT)
	$(RSCRIPT) $<

$(SURV_EXAMPLE_STAGE_ONE_PHI_23) : $(SURV_SCRIPTS)/process-submodel-three.R $(SURV_SUBMODEL_THREE_OUTPUT)
	$(RSCRIPT) $<

$(SURV_EXAMPLE_STAGE_ONE_PHI_12_POST_MEDIAN) : $(SURV_EXAMPLE_STAGE_ONE_PHI_12)
$(SURV_EXAMPLE_STAGE_ONE_PHI_23_POST_MEDIAN) : $(SURV_EXAMPLE_STAGE_ONE_PHI_23)

### Stage 2
SURV_SUBMODEL_TWO_SIMULATED_DATA = $(SURV_RDS)/submodel-two-simulated-data.rds
$(SURV_SUBMODEL_TWO_SIMULATED_DATA) : $(SURV_SCRIPTS)/simulate-data-submodel-two.R $(SURV_GLOBAL_SETTINGS) $(SURV_SIMULATION_SETTINGS)
	$(RSCRIPT) $<

### Stage 2 - sampling the melded posterior
SURV_SUBMODEL_TWO_PHI_STEP = $(SURV_MODELS)/submodel-two-phi-step.stan
SURV_SUBMODEL_TWO_PSI_STEP = $(SURV_MODELS)/submodel-two-psi-step.stan
SURV_STAGE_TWO_STAN_MODELS = $(SURV_SUBMODEL_TWO_PHI_STEP) $(SURV_SUBMODEL_TWO_PSI_STEP)
SURV_STAGE_TWO_PHI_12_SAMPLES = $(SURV_RDS)/stage-two-phi-12-samples.rds
SURV_STAGE_TWO_PHI_23_SAMPLES = $(SURV_RDS)/stage-two-phi-23-samples.rds
SURV_STAGE_TWO_PSI_2_SAMPLES = $(SURV_RDS)/stage-two-psi-2-samples.rds
SURV_STAGE_TWO_PSI_1_INDICES = $(SURV_RDS)/stage-two-psi-1-indices.rds
SURV_STAGE_TWO_PSI_3_INDICES = $(SURV_RDS)/stage-two-psi-3-indices.rds

$(SURV_STAGE_TWO_PHI_12_SAMPLES) : $(SURV_SCRIPTS)/fit-stage-two.R $(SURV_SUBMODEL_ONE_OUTPUT) $(SURV_SUBMODEL_THREE_OUTPUT) $(SURV_SUBMODEL_TWO_SIMULATED_DATA) $(SURV_STAGE_TWO_STAN_MODELS) $(SURV_GLOBAL_SETTINGS)
	$(RSCRIPT) $<

$(SURV_STAGE_TWO_PHI_23_SAMPLES) : $(SURV_STAGE_TWO_PHI_12_SAMPLES)

$(SURV_STAGE_TWO_PSI_2_SAMPLES) : $(SURV_STAGE_TWO_PHI_12_SAMPLES)

$(SURV_STAGE_TWO_PSI_1_INDICES)	: $(SURV_STAGE_TWO_PHI_12_SAMPLES)

$(SURV_STAGE_TWO_PSI_3_INDICES)	: $(SURV_STAGE_TWO_PHI_12_SAMPLES)

### Stage 2 - diagnostics
#### This form of target definition + rule will make --dry-run report
#### incorrectly, but make will only run the relevant file once.
SURV_STAGE_TWO_DIAG_PLOTS = $(wildcard plots/surv-example/stage-two*-diags.png)
$(SURV_STAGE_TWO_DIAG_PLOTS) : $(SURV_SCRIPTS)/diagnose-stage-two-plots.R $(PLOT_SETTINGS) $(SURV_STAGE_TWO_PHI_12_SAMPLES) $(SURV_STAGE_TWO_PHI_23_SAMPLES) $(SURV_STAGE_TWO_PSI_2_SAMPLES)
	$(RSCRIPT) $<

ALL_PLOTS += $(SURV_STAGE_TWO_DIAG_PLOTS)

#### The tables will be automatically picked up by TEX_FILES, under the
#### assumption that they exist first.
SURV_STAGE_TWO_DIAG_TABLES = $(wildcard tex-input/surv-example/009*-stage-two-**.tex)
$(SURV_STAGE_TWO_DIAG_TABLES) : $(SURV_SCRIPTS)/diagnose-stage-two-tables.R $(SURV_STAGE_TWO_PHI_12_SAMPLES) $(SURV_STAGE_TWO_PHI_23_SAMPLES) $(SURV_STAGE_TWO_PSI_2_SAMPLES) $(MCMC_UTIL)
	$(RSCRIPT) $<

TEX_FILES += $(SURV_STAGE_TWO_DIAG_TABLES)

### Compositional step / plots
SURV_EXAMPLE_PHI_12_SRINKAGE_PLOT = $(SURV_PLOTS)/phi-12-inter-stage-comparison.pdf
$(SURV_EXAMPLE_PHI_12_SRINKAGE_PLOT) : $(SURV_SCRIPTS)/plot-event-time-shrinkage.R $(SURV_STAGE_TWO_PHI_12_SAMPLES) $(SURV_SUBMODEL_ONE_OUTPUT) $(SURV_SIMULATION_SETTINGS)
	$(RSCRIPT) $<

ALL_PLOTS += $(SURV_EXAMPLE_PHI_12_SRINKAGE_PLOT)

SURV_EXAMPLE_PHI_23_SRINKAGE_PLOT = $(SURV_PLOTS)/phi-23-inter-stage-comparison.pdf
$(SURV_EXAMPLE_PHI_23_SRINKAGE_PLOT) : $(SURV_SCRIPTS)/plot-long-model-shrinkage.R $(SURV_STAGE_TWO_PHI_23_SAMPLES) $(SURV_SUBMODEL_THREE_OUTPUT) $(SURV_SIMULATION_SETTINGS)
	$(RSCRIPT) $<

ALL_PLOTS += $(SURV_EXAMPLE_PHI_23_SRINKAGE_PLOT)

ALL_PHI = $(SURV_EXAMPLE_STAGE_ONE_PHI_12) $(SURV_EXAMPLE_STAGE_ONE_PHI_23) $(SURV_STAGE_TWO_PHI_12_SAMPLES) $(SURV_STAGE_TWO_PHI_23_SAMPLES)

SURV_EXAMPLE_CONTRACTION_PLOT = $(SURV_PLOTS)/phi-inter-stage-posterior-sd.pdf
$(SURV_EXAMPLE_CONTRACTION_PLOT) : $(SURV_SCRIPTS)/plot-contraction.R $(PLOT_SETTINGS) $(MCMC_UTIL) $(SURV_SIMULATION_SETTINGS) $(ALL_PHI)
	$(RSCRIPT) $<

ALL_PLOTS += $(SURV_EXAMPLE_CONTRACTION_PLOT)

## point estimate comparison
SURV_EXAMPLE_POINT_EST_PSI_2_SAMPLES = $(SURV_RDS)/point-est-psi-2-samples.rds
$(SURV_EXAMPLE_POINT_EST_PSI_2_SAMPLES) : $(SURV_SCRIPTS)/fit-point-est-approx.R $(SURV_GLOBAL_SETTINGS) $(SURV_EXAMPLE_POST_MEDIANS) $(SURV_SUBMODEL_TWO_SIMULATED_DATA) $(SURV_EXAMPLE_STAGE_ONE_PHI_12) $(SURV_SUBMODEL_TWO_PSI_STEP)
	$(RSCRIPT) $<

## Half way in between point estimates
SURV_EXAMPLE_POINT_EST_1_MELD_23_PSI_2_SAMPLES = $(SURV_RDS)/point-est-1-meld-23-psi-2-samples.rds
$(SURV_EXAMPLE_POINT_EST_1_MELD_23_PSI_2_SAMPLES) : $(SURV_SCRIPTS)/fit-point-est-1-meld-23.R $(SURV_SUBMODEL_ONE_OUTPUT) $(SURV_EXAMPLE_STAGE_ONE_PHI_12_POST_MEDIAN) $(SURV_SUBMODEL_THREE_OUTPUT) $(SURV_SUBMODEL_TWO_SIMULATED_DATA) $(SURV_STAGE_TWO_STAN_MODELS)
	$(RSCRIPT) $<

SURV_EXAMPLE_POINT_EST_1_MELD_23_PHI_23_SAMPLES = $(SURV_RDS)/point-est-1-meld-23-phi-23-samples.rds
$(SURV_EXAMPLE_POINT_EST_1_MELD_23_PHI_23_SAMPLES) : $(SURV_EXAMPLE_POINT_EST_1_MELD_23_PSI_2_SAMPLES)

SURV_EXAMPLE_POINT_EST_1_MELD_23_PSI_3_INDICES = $(SURV_RDS)/point-est-1-meld-23-psi-3-indices.rds
$(SURV_EXAMPLE_POINT_EST_1_MELD_23_PSI_3_INDICES) :	$(SURV_EXAMPLE_POINT_EST_1_MELD_23_PSI_2_SAMPLES)

## and the other war
SURV_EXAMPLE_POINT_EST_3_MELD_12_PSI_2_SAMPLES = $(SURV_RDS)/point-est-3-meld-12-psi-2-samples.rds
$(SURV_EXAMPLE_POINT_EST_3_MELD_12_PSI_2_SAMPLES) : $(SURV_SCRIPTS)/fit-point-est-3-meld-12.R $(SURV_SUBMODEL_ONE_OUTPUT) $(SURV_EXAMPLE_STAGE_ONE_PHI_23_POST_MEDIAN) $(SURV_SUBMODEL_TWO_SIMULATED_DATA) $(SURV_STAGE_TWO_STAN_MODELS)
	$(RSCRIPT) $<

SURV_EXAMPLE_POINT_EST_3_MELD_12_PHI_23_SAMPLES = $(SURV_RDS)/point-est-3-meld-12-phi-23-samples.rds
$(SURV_EXAMPLE_POINT_EST_3_MELD_12_PHI_23_SAMPLES) : $(SURV_EXAMPLE_POINT_EST_3_MELD_12_PSI_2_SAMPLES)

SURV_EXAMPLE_POINT_EST_3_MELD_12_PSI_3_INDICES = $(SURV_RDS)/point-est-3-meld-12-psi-3-indices.rds
$(SURV_EXAMPLE_POINT_EST_3_MELD_12_PSI_3_INDICES) :	$(SURV_EXAMPLE_POINT_EST_3_MELD_12_PSI_2_SAMPLES)

SURV_ALL_POINT_EST_PSI_2 = $(SURV_EXAMPLE_POINT_EST_PSI_2_SAMPLES) $(SURV_EXAMPLE_POINT_EST_1_MELD_23_PSI_2_SAMPLES) $(SURV_EXAMPLE_POINT_EST_3_MELD_12_PSI_2_SAMPLES)

## compare them all!
SURV_EXAMPLE_PSI_2_COMPARISON_PLOT = $(SURV_PLOTS)/psi-2-method-comparison.pdf
$(SURV_EXAMPLE_PSI_2_COMPARISON_PLOT) : $(SURV_SCRIPTS)/plot-psi-2-comparison.R $(PLOT_SETTINGS) $(MCMC_UTIL) $(SURV_STAGE_TWO_PHI_12_SAMPLES) $(SURV_ALL_POINT_EST_PSI_2)
	$(RSCRIPT) $<

ALL_PLOTS += $(SURV_EXAMPLE_PSI_2_COMPARISON_PLOT)

# point estimate diagnostics
SURV_EXAMPLE_POINT_EST_DIAG_PLOT = $(SURV_PLOTS)/point-est-diags.png
SURV_EXAMPLE_POINT_EST_1_MELD_23_DIAG_PLOT = $(SURV_PLOTS)/point-est-1-meld-23-diags.png
SURV_EXAMPLE_POINT_EST_3_MELD_12_DIAG_PLOT = $(SURV_PLOTS)/point-est-3-meld-12-diags.png
SURV_EXAMPLE_POINT_EST_3_MELD_12_PHI_12_EVENT_ONLY_DIAG_PLOT = $(SURV_PLOTS)/point-est-3-meld-12-phi-12-event-only-diag.pdf
SURV_EXAMPLE_POINT_EST_1_MELD_23_PHI_23_EVENT_ONLY_DIAG_PLOT = $(SURV_PLOTS)/point-est-1-meld-23-phi-23-event-only-diag.pdf
$(SURV_EXAMPLE_POINT_EST_DIAG_PLOT) : $(SURV_SCRIPTS)/diagnose-point-est-all-plots.R $(PLOT_SETTINGS) $(SURV_ALL_POINT_EST_PSI_2)
	$(RSCRIPT) $<

$(SURV_EXAMPLE_POINT_EST_1_MELD_23_DIAG_PLOT) : $(SURV_EXAMPLE_POINT_EST_DIAG_PLOT)
$(SURV_EXAMPLE_POINT_EST_3_MELD_12_DIAG_PLOT) : $(SURV_EXAMPLE_POINT_EST_DIAG_PLOT)
$(SURV_EXAMPLE_POINT_EST_3_MELD_12_PHI_12_EVENT_ONLY_DIAG_PLOT) : $(SURV_EXAMPLE_POINT_EST_DIAG_PLOT)
$(SURV_EXAMPLE_POINT_EST_1_MELD_23_PHI_23_EVENT_ONLY_DIAG_PLOT) : $(SURV_EXAMPLE_POINT_EST_DIAG_PLOT)

ALL_PLOTS += $(SURV_EXAMPLE_POINT_EST_DIAG_PLOT) \
	$(SURV_EXAMPLE_POINT_EST_1_MELD_23_DIAG_PLOT) \
	$(SURV_EXAMPLE_POINT_EST_3_MELD_12_DIAG_PLOT) \
	$(SURV_EXAMPLE_POINT_EST_3_MELD_12_PHI_12_EVENT_ONLY_DIAG_PLOT) \
	$(SURV_EXAMPLE_POINT_EST_1_MELD_23_PHI_23_EVENT_ONLY_DIAG_PLOT)

SURV_EXAMPLE_POINT_EST_DIAG_TABLE = $(SURV_TEX)/0100-point-est-diag.tex
SURV_EXAMPLE_POINT_EST_1_MELD_23_DIAG_TABLE = $(SURV_TEX)/0101-point-est-1-meld-23-diag.tex
SURV_EXAMPLE_POINT_EST_3_MELD_12_DIAG_TABLE = $(SURV_TEX)/0102-point-est-3-meld-12-diag.tex
SURV_EXAMPLE_POINT_EST_1_MELD_23_PHI_23_DIAG_TABLE = $(SURV_TEX)/0104-point-est-1-meld-23-phi-23-diag.tex
SURV_EXAMPLE_POINT_EST_3_MELD_12_PHI_12_DIAG_TABLE = $(SURV_TEX)/0103-point-est-3-meld-12-phi-12-diag.tex
$(SURV_EXAMPLE_POINT_EST_DIAG_TABLE) : $(SURV_SCRIPTS)/diagnose-point-est-all-tables.R $(MCMC_UTIL) $(SURV_ALL_POINT_EST_PSI_2)
	$(RSCRIPT) $<

$(SURV_EXAMPLE_POINT_EST_1_MELD_23_DIAG_TABLE) : $(SURV_EXAMPLE_POINT_EST_DIAG_TABLE)
$(SURV_EXAMPLE_POINT_EST_3_MELD_12_DIAG_TABLE) : $(SURV_EXAMPLE_POINT_EST_DIAG_TABLE)
$(SURV_EXAMPLE_POINT_EST_1_MELD_23_PHI_23_DIAG_TABLE) : $(SURV_EXAMPLE_POINT_EST_DIAG_TABLE)
$(SURV_EXAMPLE_POINT_EST_3_MELD_12_PHI_12_DIAG_TABLE) : $(SURV_EXAMPLE_POINT_EST_DIAG_TABLE)

################################################################################
# MIMIC example
# bases
MIMIC_BASENAME = mimic-example
MIMIC_SCRIPTS = $(SCRIPTS)/$(MIMIC_BASENAME)
MIMIC_RDS = $(RDS)/$(MIMIC_BASENAME)
MIMIC_PLOTS = $(PLOTS)/$(MIMIC_BASENAME)
MIMIC_MODELS = $(MIMIC_SCRIPTS)/models
MIMIC_TEX = tex-input/$(MIMIC_BASENAME)
MIMIC_QUERIES = $(MIMIC_SCRIPTS)/queries
MIMIC_GLOBAL_SETTINGS = $(MIMIC_SCRIPTS)/GLOBALS.R

## fluid queries
MIMIC_INPUTS_CV = $(MIMIC_QUERIES)/inputs-cv.sql
MIMIC_INPUTS_MV = $(MIMIC_QUERIES)/inputs-mv.sql
MIMIC_OUTPUTS = $(MIMIC_QUERIES)/outputs.sql

MIMIC_RAW_FLUIDS = $(MIMIC_RDS)/raw-fluids-all-patients.rds
$(MIMIC_RAW_FLUIDS) : \
	$(MIMIC_SCRIPTS)/get-raw-fluids.R \
	$(MIMIC_INPUTS_CV) \
	$(MIMIC_INPUTS_MV) \
	$(MIMIC_OUTPUTS)
	$(RSCRIPT) $< \
		--inputs-cv-query $(MIMIC_INPUTS_CV) \
		--inputs-mv-query $(MIMIC_INPUTS_MV) \
		--outputs-query $(MIMIC_OUTPUTS) \
		--output $@

## blood gasses
MIMIC_PF_COHORT = $(MIMIC_RDS)/pf-cohort-and-data.rds
MIMIC_PF_QUERY = $(MIMIC_QUERIES)/blood-gasses.sql
$(MIMIC_PF_COHORT) : \
	$(MIMIC_SCRIPTS)/get-blood-gasses-and-define-pf-cohort.R \
	$(MIMIC_PF_QUERY)
	$(RSCRIPT) $< \
		--blood-gasses-query $(MIMIC_PF_QUERY) \
		--output $@

MIMIC_COMBINED_PF_RAW_FLUIDS = $(MIMIC_RDS)/combined-pf-and-raw-fluids.rds
$(MIMIC_COMBINED_PF_RAW_FLUIDS) : \
	$(MIMIC_SCRIPTS)/refine-cohort-to-minimum-overlap.R \
	$(MIMIC_RAW_FLUIDS) \
	$(MIMIC_PF_COHORT)
	$(RSCRIPT) $< \
		--pf-cohort-and-data $(MIMIC_PF_COHORT) \
		--raw-fluid-data $(MIMIC_RAW_FLUIDS) \
		--output $@

MIMIC_COMBINED_PF_SUMMARISED_FLUIDS = $(MIMIC_RDS)/combined-pf-and-summarised-fluids.rds
$(MIMIC_COMBINED_PF_SUMMARISED_FLUIDS) : \
	$(MIMIC_SCRIPTS)/refine-cohort-fluid-data.R \
	$(MIMIC_COMBINED_PF_RAW_FLUIDS) \
	$(MIMIC_GLOBAL_SETTINGS)
	$(RSCRIPT) $< \
		--combined-pf-and-raw-fluid-data $(MIMIC_COMBINED_PF_RAW_FLUIDS) \
		--mimic-globals $(MIMIC_GLOBAL_SETTINGS) \
		--output $@

MIMIC_DATA_PLOT = $(MIMIC_PLOTS)/pf-and-summarised-fluids-data.pdf
$(MIMIC_DATA_PLOT) : \
	$(MIMIC_SCRIPTS)/plot-pf-and-summarised-fluid-data.R \
	$(MIMIC_COMBINED_PF_SUMMARISED_FLUIDS) \
	$(PLOT_SETTINGS)
	$(RSCRIPT) $< \
		--combined-pf-and-summarised-fluid-data $(MIMIC_COMBINED_PF_SUMMARISED_FLUIDS) \
		--output $@

MIMIC_PF_SPLINE_MODEL_STAN = $(MIMIC_MODELS)/pf-bspline.stan
MIMIC_PF_DATA_STAN = $(MIMIC_RDS)/submodel-1-pf-data-stan-format.rds
MIMIC_PF_DATA_LIST = $(MIMIC_RDS)/submodel-1-pf-data-list-format.rds
$(MIMIC_PF_DATA_STAN) : \
	$(MIMIC_SCRIPTS)/prepare-pf-stan-data.R \
	$(MIMIC_COMBINED_PF_SUMMARISED_FLUIDS) \
	$(MIMIC_GLOBAL_SETTINGS)
	$(RSCRIPT) $< \
		--combined-pf-and-summarised-fluid-data $(MIMIC_COMBINED_PF_SUMMARISED_FLUIDS) \
		--mimic-globals $(MIMIC_GLOBAL_SETTINGS) \
		--output $@

$(MIMIC_PF_DATA_LIST) : $(MIMIC_PF_DATA_STAN)

MIMIC_PF_MODEL_SAMPLES_LONG = $(MIMIC_RDS)/submodel-1-pf-samples-long.rds
MIMIC_PF_MODEL_SAMPLES_ARRAY = $(MIMIC_RDS)/submodel-1-pf-samples-array.rds
MIMIC_PF_MODEL_SAMPLES_PLOT_MU = $(MIMIC_RDS)/submodel-1-pf-samples-plot-mu.rds

$(MIMIC_PF_MODEL_SAMPLES_LONG) : \
	$(MIMIC_SCRIPTS)/fit-pf-spline-model.R \
	$(MIMIC_PF_DATA_STAN) \
	$(MIMIC_PF_SPLINE_MODEL_STAN) \
	$(MIMIC_GLOBAL_SETTINGS)
	$(RSCRIPT) $< \
		--pf-submodel-stan-data $(MIMIC_PF_DATA_STAN) \
		--pf-submodel-stan-model $(MIMIC_PF_SPLINE_MODEL_STAN) \
		--mimic-globals $(MIMIC_GLOBAL_SETTINGS) \
		--output-array $(MIMIC_PF_MODEL_SAMPLES_ARRAY) \
		--output-plot-mu $(MIMIC_PF_MODEL_SAMPLES_PLOT_MU) \
		--output $@

$(MIMIC_PF_MODEL_SAMPLES_ARRAY) : $(MIMIC_PF_MODEL_SAMPLES_LONG)
$(MIMIC_PF_MODEL_SAMPLES_PLOT_MU) : $(MIMIC_PF_MODEL_SAMPLES_LONG)

MIMIC_PF_EVENT_TIME_SAMPLES_ARRAY = $(MIMIC_RDS)/submodel-1-event-times-samples-array.rds
MIMIC_PF_EVENT_TIME_SAMPLES_LONG = $(MIMIC_RDS)/submodel-1-event-times-samples-long.rds
$(MIMIC_PF_EVENT_TIME_SAMPLES_ARRAY) : \
	$(MIMIC_SCRIPTS)/process-pf-model-for-event-times.R \
	$(MIMIC_PF_DATA_LIST) \
	$(MIMIC_PF_MODEL_SAMPLES_LONG)
	$(RSCRIPT) $< \
	--pf-data-list-format $(MIMIC_PF_DATA_LIST) \
	--pf-submodel-samples-long $(MIMIC_PF_MODEL_SAMPLES_LONG) \
	--output-long $(MIMIC_PF_EVENT_TIME_SAMPLES_LONG) \
	--output $@

$(MIMIC_PF_EVENT_TIME_SAMPLES_LONG) : $(MIMIC_PF_EVENT_TIME_SAMPLES_ARRAY)

MIMIC_PF_FITTED_PLOT = $(MIMIC_PLOTS)/pf-data-and-bspline-fit.png
$(MIMIC_PF_FITTED_PLOT) : \
	$(MIMIC_SCRIPTS)/plot-pf-spline-fit.R \
	$(MIMIC_PF_MODEL_SAMPLES_PLOT_MU) \
	$(MIMIC_PF_DATA_LIST) \
	$(MIMIC_PF_EVENT_TIME_SAMPLES_LONG) \
	$(MIMIC_GLOBAL_SETTINGS) \
	$(MIMIC_COMBINED_PF_SUMMARISED_FLUIDS) \
	$(PLOT_SETTINGS)
	$(RSCRIPT) $< \
		--mimic-pf-plot-mu $(MIMIC_PF_MODEL_SAMPLES_PLOT_MU) \
		--mimic-pf-data-list $(MIMIC_PF_DATA_LIST) \
		--mimic-pf-event-time-long $(MIMIC_PF_EVENT_TIME_SAMPLES_LONG) \
		--mimic-globals $(MIMIC_GLOBAL_SETTINGS) \
		--combined-pf-and-summarised-fluid-data $(MIMIC_COMBINED_PF_SUMMARISED_FLUIDS) \
		--output $@

MIMIC_DEMOGRAPHICS_QUERY = $(MIMIC_QUERIES)/demographics.sql
MIMIC_MEDIAN_FIRST_DAY_LABS_QUERY = $(MIMIC_QUERIES)/median-labs-first-day.sql

MIMIC_BASELINE_DATA = $(MIMIC_RDS)/baseline-covariate-data.rds
$(MIMIC_BASELINE_DATA) : \
	$(MIMIC_SCRIPTS)/get-baseline-data.R \
	$(MIMIC_COMBINED_PF_SUMMARISED_FLUIDS) \
	$(MIMIC_DEMOGRAPHICS_QUERY) \
	$(MIMIC_MEDIAN_FIRST_DAY_LABS_QUERY)
	$(RSCRIPT) $< \
		--combined-pf-and-summarised-fluid-data $(MIMIC_COMBINED_PF_SUMMARISED_FLUIDS) \
		--demographics-query $(MIMIC_DEMOGRAPHICS_QUERY) \
		--median-labs-query $(MIMIC_MEDIAN_FIRST_DAY_LABS_QUERY) \
		--output $@


################################################################################
# knitr is becoming more picky about encoding, specify UTF-8 input
$(WRITEUP) : $(wildcard *.rmd) $(TEX_FILES) $(ALL_PLOTS) $(OWLS_DATA) $(BIBLIOGRAPHY)
	$(RSCRIPT) -e "rmarkdown::render(input = Sys.glob('*.rmd'), encoding = 'UTF-8')"