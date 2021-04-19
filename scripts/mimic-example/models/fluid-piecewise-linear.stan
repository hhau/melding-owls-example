data {
  int <lower = 1> n_icu_stays;
  int <lower = 1> n_total_obs;
  int <lower = 1, upper = n_total_obs + 1> subset_vector [n_icu_stays + 1];
  vector [n_total_obs] y_vec;
  vector [n_total_obs] x_vec;
  vector [n_icu_stays] breakpoint_lower;
  vector [n_icu_stays] breakpoint_upper;
  /*vector [n_icu_stays] intercept_means;
  vector [n_icu_stays] intercept_sds;*/

  real <lower = 0> midpoint_prior_sd;
}

transformed data {
  vector [n_icu_stays] midpoint = (breakpoint_upper + breakpoint_lower) / 2.0;
  vector [n_icu_stays] widths = breakpoint_upper - breakpoint_lower;
}

parameters {
  vector <lower = 0, upper = 1> [n_icu_stays] breakpoint_raw;
  vector <lower = 0> [2] beta_slope [n_icu_stays];
  vector <lower = 0> [n_icu_stays] beta_zero;
  real <lower = 0> y_sigma;
}

transformed parameters {
  vector [n_icu_stays] breakpoint = breakpoint_raw .* widths;
  vector [n_total_obs] mu;

  for (ii in 1 : n_icu_stays) {
    int obs_lower = subset_vector[ii];
    int obs_upper = subset_vector[ii + 1];
    int n_obs_per_icu_stay = obs_upper - obs_lower;
    vector [n_obs_per_icu_stay] indiv_obs_mu;
    vector [n_obs_per_icu_stay] indiv_obs_x = x_vec[obs_lower : (obs_upper - 1)];
    vector [n_obs_per_icu_stay] indiv_obs_y = y_vec[obs_lower : (obs_upper - 1)];

    for (jj in 1 : n_obs_per_icu_stay) {
      if (indiv_obs_x[jj] < breakpoint[ii]) {
        indiv_obs_mu[jj] = beta_zero[ii] + beta_slope[ii][1] * (indiv_obs_x[jj] - breakpoint[ii]);
      } else {
        indiv_obs_mu[jj] = beta_zero[ii] + beta_slope[ii][2] * (indiv_obs_x[jj] - breakpoint[ii]);
      }
    }
    mu[obs_lower : (obs_upper - 1)] = indiv_obs_mu;
  }
}

model {
  for (ii in 1 : n_icu_stays) {
    target += normal_lpdf(beta_slope[ii] | 5000, 1000);
  }

  target += normal_lpdf(y_vec | mu, y_sigma);
  target += normal_lpdf(beta_zero | 7000, 1000);
  target += beta_lpdf(breakpoint_raw | 8.0, 8.0);
  target += normal_lpdf(y_sigma | 0.0, 250.0);
}