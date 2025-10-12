
#if !defined(_LIBDRDYNVC_H)
#define _LIBDRDYNVC_H

#include <stdint.h>

#define LIBDRDYNVC_ERROR_NONE                   0
#define LIBDRDYNVC_ERROR_CHANID                 -1
#define LIBDRDYNVC_ERROR_MEMORY                 -2
#define LIBDRDYNVC_ERROR_SEND_DATA              -3
#define LIBDRDYNVC_ERROR_PROCESS_DATA           -4
#define LIBDRDYNVC_ERROR_NO_CALLBACK            -5
#define LIBDRDYNVC_ERROR_LOG                    -6
#define LIBDRDYNVC_ERROR_CAP_REQUEST            -7
#define LIBDRDYNVC_ERROR_CAP_RESPONSE           -8
#define LIBDRDYNVC_ERROR_CREATE_REQUEST         -9
#define LIBDRDYNVC_ERROR_CREATE_RESPONSE        -10
#define LIBDRDYNVC_ERROR_CHANNEL_ID             -11
#define LIBDRDYNVC_ERROR_DATA_FIRST             -12
#define LIBDRDYNVC_ERROR_DATA                   -13
#define LIBDRDYNVC_ERROR_CLOSE                  -14

struct drdynvc_t
{
    int (*log_msg)(struct drdynvc_t* drdynvc, const char* msg);
    int (*send_data)(struct drdynvc_t* drdynvc, uint16_t channel_id,
                     void* data, uint32_t bytes);
    int (*process_cap_request)(struct drdynvc_t* drdynvc,
                               uint16_t channel_id,
                               uint16_t version,
                               uint16_t pc0, uint16_t pc1,
                               uint16_t pc2, uint16_t pc3);
    int (*process_create_request)(struct drdynvc_t* drdynvc,
                                  uint16_t channel_id,
                                  uint32_t drdynvc_channel_id,
                                  const char* drdynvc_channel_name);
    int (*process_data_first)(struct drdynvc_t* drdynvc,
                              uint16_t channel_id,
                              uint32_t drdynvc_channel_id,
                              uint32_t total_bytes,
                              void* data, uint32_t bytes);
    int (*process_data)(struct drdynvc_t* drdynvc,
                        uint16_t channel_id,
                        uint32_t drdynvc_channel_id,
                        void* data, uint32_t bytes);
    int (*process_close)(struct drdynvc_t* drdynvc,
                         uint16_t channel_id,
                         uint32_t drdynvc_channel_id);
    void* user;
};

int drdynvc_init(void);
int drdynvc_deinit(void);
int drdynvc_create(struct drdynvc_t** drdynvc);
int drdynvc_delete(struct drdynvc_t* drdynvc);
int drdynvc_process_data(struct drdynvc_t* drdynvc,
                         uint16_t channel_id,
                         void* data, uint32_t bytes);
int drdynvc_send_cap_response(struct drdynvc_t* drdynvc,
                              uint16_t channel_id,
                              uint16_t version);
int drdynvc_send_create_response(struct drdynvc_t* drdynvc,
                                 uint16_t channel_id,
                                 uint32_t drdynvc_channel_id,
                                 int32_t creation_status);
int drdynvc_send_data_first(struct drdynvc_t* drdynvc,
                            uint16_t channel_id,
                            uint32_t drdynvc_channel_id,
                            uint32_t total_bytes,
                            void* data, uint32_t bytes);
int drdynvc_send_data(struct drdynvc_t* drdynvc,
                      uint16_t channel_id,
                      uint32_t drdynvc_channel_id,
                      void* data, uint32_t bytes);

#endif
