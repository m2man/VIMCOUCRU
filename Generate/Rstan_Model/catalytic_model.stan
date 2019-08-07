
            data{
                int <lower = 1> Ngroup;
                vector <lower = 0, upper = 99> [Ngroup] age_low;
                vector <lower = 0, upper = 99> [Ngroup] age_up;
                vector <lower = 1> [Ngroup] pop_agegroup;
                vector <lower = 0> [Ngroup] case_agegroup;
                int <lower = 0> total_case;
            }
            
            transformed data{
                vector [Ngroup] log_case_agegroup_factorial;
                real log_total_case_factorial;
                log_total_case_factorial = lgamma(total_case + 1);
                log_case_agegroup_factorial = lgamma(case_agegroup + 1);
            }
            
            parameters{
                real <lower = 0> lambda;
                real <lower = 0, upper = 1> p;
            }
            
            transformed parameters{
                vector[Ngroup] Lp;
                vector[Ngroup] Le;
                real LMN;
                real LMNP;
                for (i in 1 : Ngroup){
                    Lp[i] = exp(-lambda * age_low[i]) - exp(-lambda*(age_up[i] + 1));
                    Le[i] = Lp[i] * pop_agegroup[i] * p;
                }
                LMN = log_total_case_factorial - sum(log_case_agegroup_factorial) + sum(case_agegroup .* log(Le / sum(Le)));
                LMNP = LMN + total_case * log(sum(Le)) - sum(Le) - log_total_case_factorial;
            }
            
            model{
                lambda ~ normal(0, 1000);
                p ~ uniform(0, 1);
                target += LMNP;
            }
            
