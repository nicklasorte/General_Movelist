function [rand_seed1]=gen_mc_rand_seed_rev1(mc_size)
%%%%%%%%Generate the rand_seed1 used by parfor chunks for MC sampling.
tempx=ceil(rand(1)*mc_size);
tempy=ceil(rand(1)*mc_size);
rand_seed1=tempx+tempy;
end
