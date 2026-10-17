<script>
import { DEFAULT_REDIRECT_URL } from 'dashboard/constants/globals';
import { verifyPasswordToken } from '../../../api/auth';
import Spinner from 'shared/components/Spinner.vue';

export default {
  components: { Spinner },
  data() {
    return { confirmationFailed: false };
  },
  props: {
    confirmationToken: {
      type: String,
      default: '',
    },
  },
  mounted() {
    this.confirmToken();
  },
  methods: {
    async confirmToken() {
      try {
        await verifyPasswordToken({
          confirmationToken: this.confirmationToken,
        });
        window.location = DEFAULT_REDIRECT_URL;
      } catch (error) {
        this.confirmationFailed = true;
      }
    },
  },
};
</script>

<template>
  <div
    class="flex items-center justify-center min-h-screen h-full bg-n-background w-full"
  >
    <template v-if="!confirmationFailed">
      <Spinner color-scheme="primary" size="" />
      <div class="ml-2 text-n-slate-11">{{ $t('CONFIRM_EMAIL') }}</div>
    </template>
    <div v-else class="mx-auto max-w-md px-6 text-center">
      <p class="text-n-slate-12">{{ $t('CONFIRM_EMAIL_FAILED') }}</p>
      <a class="mt-4 inline-block text-n-blue-11" href="/app/login">{{ $t('LOGIN') }}</a>
    </div>
  </div>
</template>
