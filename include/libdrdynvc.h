
#if !defined(_LIBDRVYNVC_H)
#define _LIBDRVYNVC_H

#include <stdint.h>

#define LIBDRVYNVC_ERROR_NONE           0
#define LIBDRVYNVC_ERROR_CHANID         -1
#define LIBDRVYNVC_ERROR_MEMORY         -2
#define LIBDRVYNVC_ERROR_SEND_DATA      -3
#define LIBDRVYNVC_ERROR_PROCESS_DATA   -4
#define LIBDRVYNVC_ERROR_NO_CALLBACK    -5

struct drvynvc_t
{
    int (*process_data)(struct drvynvc_t* svc, uint16_t channel_id,
                        void* data, uint32_t bytes);
    void* user;
};

struct drvynvc_channels_t
{
    int (*log_msg)(struct drvynvc_channels_t* drvynvc, const char* msg);
    int (*send_data)(struct drvynvc_channels_t* drvynvc, uint16_t channel_id,
                     uint32_t total_bytes, uint32_t flags,
                     void* data, uint32_t bytes);
    struct drvynvc_t channels[16];
    void* user;
};

int drvynvc_init(void);
int drvynvc_deinit(void);
int drvynvc_create(struct drvynvc_channels_t** drvynvc_channels);
int drvynvc_delete(struct drvynvc_channels_t* drvynvc_channels);
/* data from server to client, may call drvynvc_t::process_data above */
int drvynvc_process_data(struct drvynvc_channels_t* drvynvc_channels,
                         uint16_t channel_id,
                         void* data, uint32_t bytes);
/* data from client to server, should call drvynvc_channels_t::send_data */
int drvynvc_send_data(struct drvynvc_channels_t* drvynvc_channels,
                      uint16_t channel_id,
                      void* data, uint32_t bytes);
   
#endif
