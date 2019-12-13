#include "tsqueue.h"

void threadsafe_queue_init(ThreadsafeQueue *q) {
    queue_init(&q->q);
    pthread_mutex_init(&q->mutex, nullptr);
    pthread_cond_init(&q->cond, nullptr);
}

void threadsafe_queue_destroy(ThreadsafeQueue *q) {
    pthread_cond_destroy(&q->cond);
    pthread_mutex_destroy(&q->mutex);
    queue_destroy(&q->q);
}

void threadsafe_queue_push(ThreadsafeQueue *q, void *data) {
    pthread_mutex_lock(&q->mutex);
    queue_push(&q->q, data);
    pthread_cond_signal(&q->cond);
    pthread_mutex_unlock(&q->mutex);
}

bool threadsafe_queue_try_pop(ThreadsafeQueue *q, void **data) {
    void *poped_data;
    if (queue_empty(&q->q)) {
        return false;
    }
    pthread_mutex_lock(&q->mutex);
    poped_data = queue_pop(&q->q);
    pthread_mutex_unlock(&q->mutex);
    if (data != nullptr)
        *data = poped_data;

    return true;
}

void *threadsafe_queue_wait_and_pop(ThreadsafeQueue *q) {
    void *poped_data;
    pthread_mutex_lock(&q->mutex);
    while (queue_empty(&q->q)) {
        pthread_cond_wait(&q->cond, &q->mutex);
    }
    poped_data = queue_pop(&q->q);
    pthread_mutex_unlock(&q->mutex);

    return poped_data;
}
