
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
#define LIBDRDYNVC_ERROR_CAPABILITIES_REQUEST   -7
#define LIBDRDYNVC_ERROR_CAPABILITIES_RESPONSE  -8

struct drdynvc_t
{
    int (*log_msg)(struct drdynvc_t* drdynvc, const char* msg);
    int (*send_data)(struct drdynvc_t* drdynvc, uint16_t channel_id,
                     void* data, uint32_t bytes);
    int (*capabilities_request)(struct drdynvc_t* drdynvc,
                                uint16_t channel_id, uint16_t version,
                                uint16_t pc0, uint16_t pc1,
                                uint16_t pc2, uint16_t pc3);
    int (*create_request)(struct drdynvc_t* drdynvc, uint16_t channel_id,
                          uint32_t drdynvc_channel_id,
                          const char* drdynvc_channel_name);
    void* user;
};

int drdynvc_init(void);
int drdynvc_deinit(void);
int drdynvc_create(struct drdynvc_t** drdynvc);
int drdynvc_delete(struct drdynvc_t* drdynvc);
int drdynvc_process_data(struct drdynvc_t* drdynvc,
                         uint16_t channel_id,
                         void* data, uint32_t bytes);
int drdynvc_capabilities_response(struct drdynvc_t* drdynvc,
                                  uint16_t channel_id, uint16_t version);
int drdynvc_create_response(struct drdynvc_t* drdynvc, uint16_t channel_id,
                            uint32_t drdynvc_channel_id,
                            int32_t creation_status);

#endif
