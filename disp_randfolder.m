function disp_randfolder(app,label1)

    if isa(app,'double')
        label1
        %pause(0.01)
    else
        app.TextArea_RandFolder.Value={label1};
        pause(0.01)
    end
    
end