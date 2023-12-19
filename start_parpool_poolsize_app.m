function [poolobj,cores]=start_parpool_poolsize_app(app,parallel_flag,workers)
    
 if parallel_flag==1
     poolobj=gcp('nocreate');
     if isempty(poolobj)
         %poolobj=parpool(workers);
         poolobj=parpool(workers,'IdleTimeout',120);
     end
     cores=poolobj.NumWorkers
 else
     poolobj=NaN(1);
     poolobj=poolobj(~isnan(poolobj))
     cores=1
 end

end