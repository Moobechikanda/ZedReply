<script setup>
import { reactive, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';

const props = defineProps({
  assistant: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['submit']);

const { t } = useI18n();

const initialState = {
  name: '',
  description: '',
  productName: '',
  features: {
    conversationFaqs: false,
    memories: false,
    citations: false,
    contactAttributes: false,
  },
};

// Keep these keys aligned with Captain::Assistant::BUSINESS_PROFILE_FIELDS.
const businessProfileFields = [
  { key: 'offerings_and_pricing', translationKey: 'OFFERINGS_AND_PRICING' },
  { key: 'business_hours', translationKey: 'BUSINESS_HOURS' },
  {
    key: 'locations_and_service_area',
    translationKey: 'LOCATIONS_AND_SERVICE_AREA',
  },
  { key: 'policies', translationKey: 'POLICIES' },
  { key: 'faqs_and_eligibility', translationKey: 'FAQS_AND_ELIGIBILITY' },
  { key: 'response_limits', translationKey: 'RESPONSE_LIMITS' },
  { key: 'human_handoff', translationKey: 'HUMAN_HANDOFF' },
  { key: 'connected_systems', translationKey: 'CONNECTED_SYSTEMS' },
];

const emptyBusinessProfile = () =>
  Object.fromEntries(businessProfileFields.map(({ key }) => [key, '']));

const businessProfileInputs = computed(() =>
  businessProfileFields.map(({ key, translationKey }) => ({
    key,
    label: t(
      `CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.${translationKey}.LABEL`
    ),
    placeholder: t(
      `CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.${translationKey}.PLACEHOLDER`
    ),
  }))
);

const state = reactive({
  ...initialState,
  businessProfile: emptyBusinessProfile(),
});

const validationRules = {
  name: { required, minLength: minLength(1) },
  description: { required, minLength: minLength(1) },
  productName: { required, minLength: minLength(1) },
};

const v$ = useVuelidate(validationRules, state);

const getErrorMessage = field => {
  return v$.value[field].$error ? v$.value[field].$errors[0].$message : '';
};

const formErrors = computed(() => ({
  name: getErrorMessage('name'),
  description: getErrorMessage('description'),
  productName: getErrorMessage('productName'),
}));

const updateStateFromAssistant = assistant => {
  const { config = {} } = assistant;
  state.name = assistant.name;
  state.description = assistant.description;
  state.productName = config.product_name;
  state.businessProfile = {
    ...emptyBusinessProfile(),
    ...config.business_profile,
  };
  state.features = {
    conversationFaqs: config.feature_faq || false,
    memories: config.feature_memory || false,
    citations: config.feature_citation || false,
    contactAttributes: config.feature_contact_attributes || false,
  };
};

const handleBasicInfoUpdate = async () => {
  const result = await Promise.all([
    v$.value.name.$validate(),
    v$.value.description.$validate(),
    v$.value.productName.$validate(),
  ]).then(results => results.every(Boolean));
  if (!result) return;

  const payload = {
    name: state.name,
    description: state.description,
    config: {
      ...props.assistant.config,
      product_name: state.productName,
      business_profile: { ...state.businessProfile },
      feature_faq: state.features.conversationFaqs,
      feature_memory: state.features.memories,
      feature_citation: state.features.citations,
      feature_contact_attributes: state.features.contactAttributes,
    },
  };

  emit('submit', payload);
};

watch(
  () => props.assistant,
  newAssistant => {
    if (newAssistant) updateStateFromAssistant(newAssistant);
  },
  { immediate: true }
);
</script>

<template>
  <div class="flex flex-col gap-6">
    <Input
      v-model="state.name"
      :label="t('CAPTAIN.ASSISTANTS.FORM.NAME.LABEL')"
      :placeholder="t('CAPTAIN.ASSISTANTS.FORM.NAME.PLACEHOLDER')"
      :message="formErrors.name"
      :message-type="formErrors.name ? 'error' : 'info'"
    />

    <Input
      v-model="state.productName"
      :label="t('CAPTAIN.ASSISTANTS.FORM.PRODUCT_NAME.LABEL')"
      :placeholder="t('CAPTAIN.ASSISTANTS.FORM.PRODUCT_NAME.PLACEHOLDER')"
      :message="formErrors.productName"
      :message-type="formErrors.productName ? 'error' : 'info'"
    />

    <Editor
      v-model="state.description"
      :max-length="500"
      :label="t('CAPTAIN.ASSISTANTS.FORM.DESCRIPTION.LABEL')"
      :placeholder="t('CAPTAIN.ASSISTANTS.FORM.DESCRIPTION.PLACEHOLDER')"
      :message="formErrors.description"
      :message-type="formErrors.description ? 'error' : 'info'"
      class="z-0"
    />

    <section class="flex flex-col gap-4 border-t border-n-weak pt-5">
      <div class="flex flex-col gap-1">
        <h3 class="text-base font-medium text-n-slate-12">
          {{ t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.TITLE') }}
        </h3>
        <p class="mb-0 text-sm text-n-slate-11">
          {{ t('CAPTAIN.ASSISTANTS.FORM.BUSINESS_PROFILE.DESCRIPTION') }}
        </p>
      </div>
      <div class="flex flex-col gap-4">
        <div v-for="field in businessProfileInputs" :key="field.key">
          <TextArea
            :id="`business-profile-${field.key}`"
            v-model="state.businessProfile[field.key]"
            :label="field.label"
            :placeholder="field.placeholder"
            auto-height
            min-height="6rem"
            max-height="18rem"
          />
        </div>
      </div>
    </section>

    <div class="flex flex-col gap-2">
      <label class="text-sm font-medium text-n-slate-12">
        {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.TITLE') }}
      </label>
      <div class="flex flex-col gap-2">
        <label class="flex items-center gap-2">
          <input v-model="state.features.conversationFaqs" type="checkbox" />
          {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_CONVERSATION_FAQS') }}
        </label>
        <label class="flex items-center gap-2">
          <input v-model="state.features.memories" type="checkbox" />
          {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_MEMORIES') }}
        </label>
        <label class="flex items-center gap-2">
          <input v-model="state.features.citations" type="checkbox" />
          {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_CITATIONS') }}
        </label>
        <label class="flex items-center gap-2">
          <input v-model="state.features.contactAttributes" type="checkbox" />
          {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_CONTACT_ATTRIBUTES') }}
        </label>
      </div>
    </div>

    <div>
      <Button
        :label="t('CAPTAIN.ASSISTANTS.FORM.UPDATE')"
        @click="handleBasicInfoUpdate"
      />
    </div>
  </div>
</template>
