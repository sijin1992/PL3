function test_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        return 1,"this is fail resp"
    elseif step == 1 then
        return datablock.main_data, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function test_do_logic(req, user_name, main_data_buf)
    local pb = require "protobuf"
    main_data = pb.decode("UserInfo", main_data_buf)
    main_data["level"] = main_data["level"] + 1
    new_main_data_buf = pb.encode("UserInfo", main_data)
    return "this is resp",new_main_data_buf
end