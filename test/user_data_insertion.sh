#!/usr/bin/env bash

NUM_USERS=10000

# create_user(){
#       local user_index=$1
      
#       dfx identity new user${user_index} --storage-mode=plaintext || true

# dfx --identity user${user_index} canister call regions_implementation_backend storeuser \
# "(record {id = principal \"be2us-64aaa-aaaaa-qaabq-cai\"; name = \"user${user_index}\"; email = \"user${user_index}@gmail.com\"; gender = variant {male}; isAdmin = true; rating = 5})"
# }

delete_user() {
  local user_index=$1
  dfx identity remove user${user_index}
}

# get_user(){
#     local user_index=$1
#     dfx --identity user${user_index} canister call regions_implementation_backend getUser
# }

# export -f create_user
export -f delete_user
# export -f get_user

# start_time_create=$(date +%s)
# seq $NUM_USERS | parallel -j10 create_user
# end_time_create=$(date +%s)

start_time_delete=$(date +%s)
seq $NUM_USERS | parallel -j10 delete_user
end_time_delete=$(date +%s)

# start_time_get=$(date +%s)
# seq $NUM_USERS | parallel -j10 get_user
# end_time_get=$(date +%s)
# echo "Insertion time: $((end_time_create - start_time_create)) seconds"