data {
  // global constant
  int <lower = 1> n_icu_stays;
  int <lower = 1> n_theta; // includes intercept
  int <lower = 1> n_segments;

  // Y_{2} - baseline data
  matrix [n_icu_stays, n_theta] baseline_data_x;
  real log_crude_event_rate;

  // phi_{1 \cap 2} -- from the event time submodel
  int <lower = 0, upper = 1> event_indicator [n_icu_stays];
  vector <lower = 0> [n_icu_stays] event_time;

  // phi_{2 \cap 3} -- from the longitudinal submodel
  // used to calculate m_{i}(t)
  vector [n_icu_stays] breakpoint;
  vector [n_segments] eta_slope [n_icu_stays]; // first segment is eta^{b} -- eta 'before'
}

parameters {
  // intercept and baseline covariates
  vector [n_theta] theta;

  // baseline hazard parameter(s) (Weibull gamma)
  real <lower = 0> hazard_gamma;

  // longitudinal associative strength (alpha)
  real alpha;
}

model {
  for (ii in 1 : n_icu_stays) {
    real temp_surv_prob_common;
    if (event_indicator[ii] == 1) { // add the respiratory failure hazard
      target += log(hazard_gamma) + (hazard_gamma - 1) * log(event_time[ii]);
      target += baseline_data_x[ii, ] * theta;

      if (event_time[ii] < breakpoint[ii]) {
        target += alpha * eta_slope[ii][1];
      } else {
        target += alpha * eta_slope[ii][2];
      }
    }

    // always add the survival probability
    // this term is common despite to both cases
    // first add -H_{i,1}(T_i) -- negative cumulative hazard for the resp. fail.
    temp_surv_prob_common = -exp(baseline_data_x[ii, ] * theta);

    if (event_time[ii] < breakpoint[ii]) {
      real t1 = exp(alpha * eta_slope[ii][1]);
      real t2 = pow(event_time[ii], hazard_gamma);
      real temp_lower =  t1 * t2;
      target += temp_surv_prob_common * temp_lower;
    } else {
      real t1 = exp(alpha * eta_slope[ii][1]);
      real t2 = pow(breakpoint[ii], hazard_gamma);
      real t3 = exp(alpha * eta_slope[ii][2]);
      real t4 = pow(event_time[ii], hazard_gamma);
      real temp_upper = (t1 * t2) + (t3) * (t4 - t2);
      target += temp_surv_prob_common * temp_upper;
    }

  }

  // priors -- only psi_2 in this model
  target += normal_lpdf(theta[1] | log_crude_event_rate, 0.5);
  target += skew_normal_lpdf(theta[2 : n_theta] | 0, 0.5, -1);
  target += gamma_lpdf(hazard_gamma | 9.05, 8.72);
  target += skew_normal_lpdf(alpha | 0.0, 0.5, -2);
}
